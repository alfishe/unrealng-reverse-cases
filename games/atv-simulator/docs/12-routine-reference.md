# 12. Routine reference

Every code entry of the game, in address order by module (`src/game/<module>.asm`). The name, the title and
the description are the source's (`src/game/game.ann`); the rest is what the recordings saw: `work/stage1/rec/c1` (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT), and the case's other recordings (`case.json` `read_builds`, `code_builds`): their calls in a Runs row of their own, their callers, callees, reads and writes (`read_builds` only) with the others'. They are local, not in the repository; the WALKTHROUGH's commands rebuild them.
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
| [`menu`](#menu) | `$6338`-`$69F6`, `$6A09`-`$7A3D`, `$83F9`-`$8546`, `$858A`-`$85CF` | 136 of 155 |
| [`render`](#render) | `$69F7`-`$6A08`, `$8080`-`$83F8`, `$8547`-`$8589`, `$85D0`-`$D6AF`, `$DBD1`-`$DE37`, `$F03C`-`$F84F` | 99 of 111 |
| [`scores`](#scores) | `$7A3E`-`$7C9B`, `$DBB0`-`$DBD0`, `$EABF`-`$EC7E`, `$EDBB`-`$EE83` | 29 of 32 |
| [`trails`](11-data-reference.md#trails) | `$7C9C`-`$807F`, `$EE84`-`$F03B` | 0 of 13 |
| [`loop`](#loop) | `$D6B0`-`$D70D`, `$D80D`-`$DA1D`, `$EC7F`-`$EDBA` | 42 of 43 |
| [`vehicle`](#vehicle) | `$D70E`-`$D7D5`, `$DA1E`-`$DBAF`, `$DE38`-`$EABE` | 61 of 71 |
| [`entry`](#entry) | `$D7D6`-`$D80C` | 1 of 1 |
| [`sound`](#sound) | `$F850`-`$FF77` | 31 of 40 |

## menu

`src/game/menu.asm`

### `MenuTable` (`$69A6`)

**The front end's jump table; the first entry JP Title**

Each entry is a JP. The game calls Title, InitTextWidths, Random, Print, LoadIntro, TrailIntro, ShowHud, FillAttrs, PixelMask, MenuSpriteAttrs, DetectKempston, BuildRowAddrs, BuildBufferRows, InitListWidths and CheckHiScore through it; the entries at `$69AC`, `$69AF`, `$69B5`, `$69B8`, `$69BB`, `$69BE`, `$69C7`, `$69CA`, `$69CD`, `$69D9`, `$69E2` and `$69E5` are called by no one (known only from the code).

Witness: L1 4 (c1, trail1, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 2 calls, 20 t-states own (0.00 %) |
| Runs (the other recordings) | 2 calls (`stage1/rec/trail1` 1, `stage1/rec/warp` 1) |
| Called from | `GameEntry` |
| Calls | `Title` (tail) |

### `JpInitTextWidths` (`$69A9`)

**JP InitTextWidths**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 1 call, 10 t-states own (0.00 %) |
| Called from | `Init` |
| Calls | `InitTextWidths` (tail) |

### `JpFrameBox` (`$69AC`)

**JP FrameBox**

Known only from the code: no recording runs it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `JpDissolve` (`$69AF`)

**JP Dissolve**

Known only from the code: no recording runs it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `JpRandom` (`$69B2`)

**JP Random**

Witness: L1 1690 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 50 calls, 616 t-states own (0.00 %) |
| Runs (the other recordings) | 1,640 calls (`stage1/rec/kb` 620, `stage1/rec/warp` 330, `stage1/rec/empty` 230 and 7 more) |
| Called from | `Noise` |
| Calls | `Random` (tail) |

### `JpAnyKey` (`$69B5`)

**JP AnyKey**

Known only from the code: no recording runs it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `JpSelectKey` (`$69B8`)

**JP SelectKey**

Known only from the code: no recording runs it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `JpReadNewKey` (`$69BB`)

**JP ReadNewKey**

Known only from the code: no recording runs it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `JpShowBufferAt` (`$69BE`)

**JP ShowBufferAt**

Known only from the code: no recording runs it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `JpPrint` (`$69C1`)

**JP Print**

Witness: L1 2368 (c1, empty, kb, trail1, trails, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 2 calls, 35 t-states own (0.00 %) |
| Runs (the other recordings) | 2,366 calls (`stage1/rec/trails` 1,612, `stage1/rec/warp` 434, `stage1/rec/empty` 166 and 3 more) |
| Called from | `PrintShadow` (tail) |
| Calls | `Print` (tail) |

### `JpLoadIntro` (`$69C4`)

**JP LoadIntro**

Witness: L1 11 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 1 call, 10 t-states own (0.00 %) |
| Runs (the other recordings) | 10 calls (`stage1/rec/empty` 1, `stage1/rec/fuel` 1, `stage1/rec/kb` 1 and 7 more) |
| Called from | `NewGame` |
| Calls | `LoadIntro` (tail) |

### `JpChecker` (`$69C7`)

**JP Checker**

Known only from the code: no recording runs it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `JpSpriteList` (`$69CA`)

**JP SpriteList**

Known only from the code: no recording runs it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `JpAttrBoxes` (`$69CD`)

**JP AttrBoxes**

Known only from the code: no recording runs it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `JpTrailIntro` (`$69D0`)

**JP TrailIntro**

Witness: L1 21 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 1 call, 10 t-states own (0.00 %) |
| Runs (the other recordings) | 20 calls (`stage1/rec/warp` 8, `stage1/rec/kb` 2, `stage1/rec/trails` 2 and 7 more) |
| Called from | `NewGame` |
| Calls | `TrailIntro` (tail) |

### `JpShowHud` (`$69D3`)

**JP ShowHud**

Witness: L1 21 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 1 call, 10 t-states own (0.00 %) |
| Runs (the other recordings) | 20 calls (`stage1/rec/warp` 8, `stage1/rec/wallcrash` 2, `stage1/rec/kb` 2 and 7 more) |
| Called from | `NewGame` |
| Calls | `ShowHud` (tail) |

### `JpFillAttrs` (`$69D6`)

**JP FillAttrs**

Witness: L1 11 (kb, trails, wallcrash, warp).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 11 calls (`stage1/rec/warp` 7, `stage1/rec/kb` 2, `stage1/rec/trails` 1 and 1 more) |
| Called from | `BandP1` (tail), `BandP2` (tail) |
| Calls | `FillAttrs` (tail) |

### `JpAttrAddr` (`$69D9`)

**JP AttrAddr**

Known only from the code: no recording runs it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `JpPixelMask` (`$69DC`)

**JP PixelMask**

Witness: L1 26704 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 2,400 calls, 34,032 t-states own (0.00 %) |
| Runs (the other recordings) | 24,304 calls (`stage1/rec/kb` 6,504, `stage1/rec/fuel` 5,016, `stage1/rec/trails` 3,684 and 7 more) |
| Called from | `GroundScan` |
| Calls | `PixelMask` (tail) |

### `JpMenuSpriteAttrs` (`$69DF`)

**JP MenuSpriteAttrs**

Witness: L1 2139 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 54 calls, 712 t-states own (0.00 %) |
| Runs (the other recordings) | 2,085 calls (`stage1/rec/warp` 641, `stage1/rec/trails` 531, `stage1/rec/kb` 284 and 7 more) |
| Called from | `DeferAttrs` |
| Calls | `MenuSpriteAttrs` (tail) |

### `JpClearPixels` (`$69E2`)

**JP ClearPixels**

Known only from the code: no recording runs it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `JpFillAttrsBase` (`$69E5`)

**JP FillAttrsBase**

Known only from the code: no recording runs it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `JpDetectKempston` (`$69E8`)

**JP DetectKempston**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 1 call, 10 t-states own (0.00 %) |
| Called from | `Init` |
| Calls | `DetectKempston` (tail) |

### `JpBuildRowAddrs` (`$69EB`)

**JP BuildRowAddrs**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 1 call, 10 t-states own (0.00 %) |
| Called from | `Init` |
| Calls | `BuildRowAddrs` (tail) |

### `JpBuildBufferRows` (`$69EE`)

**JP BuildBufferRows**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 1 call, 19 t-states own (0.00 %) |
| Called from | `Init` |
| Calls | `BuildBufferRows` (tail) |

### `JpInitListWidths` (`$69F1`)

**JP InitListWidths**

Witness: L1 21 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 1 call, 10 t-states own (0.00 %) |
| Runs (the other recordings) | 20 calls (`stage1/rec/warp` 8, `stage1/rec/kb` 2, `stage1/rec/trails` 2 and 7 more) |
| Called from | `NewGame` |
| Calls | `InitListWidths` (tail) |

### `JpCheckHiScore` (`$69F4`)

**JP CheckHiScore**

Witness: L1 4 (c1, kb, trail1, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 1 call, 10 t-states own (0.00 %) |
| Runs (the other recordings) | 3 calls (`stage1/rec/kb` 1, `stage1/rec/trail1` 1, `stage1/rec/warp` 1) |
| Called from | `GameEntry` |
| Calls | `CheckHiScore` (tail) |

### `LoadIntro` (`$6A09`)

**The intro before the first menu: clear, a checkered band, the ATV and the boxes of the loading picture**

Clears the screen (ClearScreen), draws a checkered band (Checker) and the sprite list LoadIntroSprites with the menu bank, then the attribute boxes LoadIntroBoxes. Called through JpLoadIntro by NewGame.

Witness: L1 11 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 1 call, 62,791 t-states own (0.00 %) |
| Runs (the other recordings) | 10 calls (`stage1/rec/empty` 1, `stage1/rec/fuel` 1, `stage1/rec/speedcrash` 1 and 7 more) |
| Called from | `JpLoadIntro` (tail) |
| Calls | `Checker`, `SpriteList`, `AttrBoxes` (tail), `ClearScreen` |
| Reads | `$6A0D` (`LoadIntro+4`) |
| Writes | `$6C2A`-`$6C2B` (`SpriteListCall+1`); `$80DB`-`$80DD` (`SpriteX`, `SpriteY`); `$82F8`-`$82F9` (`ModeVector`) |

### `TrailIntro` (`$6A38`)

**The trail's intro: "TRAIL NO." and the trail's number in big print, the name, the panels**

Clears the screen's attributes and pixels, prints TrailNoText twice (shadow and face) at scale 2 x 5, the trail's number (Trail + "b", a big digit) at scale 2 x 4, dissolves the buffer onto the screen, waits 50 frames, copies the trail's name (CopyTrailName) and prints it and the intro picture (TrailIntroBoxes), waits 150 frames, then draws one or two players' panels (PanelP1, PanelP2), each coloured by TrailAttrs. Called through JpTrailIntro before each trail (c1 frame 15 800).

Witness: L1 21 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 1 call, 13,165,766 t-states own (0.84 %) |
| Runs (the other recordings) | 20 calls (`stage1/rec/warp` 8, `stage1/rec/wallcrash` 2, `stage1/rec/trails` 2 and 7 more) |
| Called from | `JpTrailIntro` (tail) |
| Calls | `PanelP2`, `PanelP1`, `AttrBoxes`, `Dissolve`, `PrintAt`, `ClearTopHalf`, `ClearBottomHalf`, `FillAllAttrs`, `CopyTrailName`, `TrailAttrs` (tail), `ShowBufferPlace`, `ScreenAddrHL`, `JpClearBufferP1` |
| Reads | `$6AE7` (`l_6AE6+1`); `$6B1A` (`l_6B19+1`); `$D6BE`-`$D6BF` (`Riding`, `Trail`) |
| Writes | `$6958`-`$6968` (`BigScaleX`, `HiScoreTitle`); `$6C2A`-`$6C2B` (`SpriteListCall+1`); `$8084`-`$8085` (`AttrBase`); `$8144`-`$8145` (`BufferBase`); `$82F8`-`$82F9` (`ModeVector`) |

### `FillColumn` (`$6B3B`)

**Write E into B lines down from HL (screen)**

Witness: L1 4006 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 2 calls, 9,948 t-states own (0.00 %) |
| Runs (the other recordings) | 44 calls (`stage1/rec/warp` 16, `stage1/rec/kb` 8, `stage1/rec/wallcrash` 4 and 7 more) |
| Called from | `PanelP2`, `PanelP1` |
| Calls | `JpNextLineHL` |
| Writes | `$4020`-`$53E0` (screen); `$53F7`-`$54E0` (screen); `$54F7`-`$55C0` (screen); `$55D7`-`$55E0` (screen); `$55F7`-`$56C0` (screen); `$56D7`-`$56E0` (screen); 2 more ranges |

### `PanelP2` (`$6B42`)

**The second player's half: its frame, its HUD, the FUEL and SPEED bars**

The bottom half's sprite list PanelP2Sprites, the side lines (E = `$0F` / `$F0` down 88 lines), the record copy (CopyRecordP2), the HUD at y 6, ShowBars, ShowMaxTime and the attribute boxes PanelP2Boxes. Only in a two-player game (menu: 2 runs).

Witness: L1 2 (kb).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 2 calls (`stage1/rec/kb` 2) |
| Called from | `TrailIntro` |
| Calls | `FillColumn`, `SpriteList`, `AttrBoxes`, `ClearBottomHalf`, `TrailAttrs` (tail), `ScreenAddrHL`, `JpLoadRecordP2`, `JpSaveRecordP2`, `JpShowBars` |
| Writes | `$57E0` (screen); `$57F7` (screen); `$D6C2` (`HudY`) |

### `PanelP1` (`$6B8C`)

**The first player's half: its frame, its HUD, the bars**

As PanelP2 for the top half (y `$BE`).

Witness: L1 21 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 1 call, 536 t-states own (0.00 %) |
| Runs (the other recordings) | 20 calls (`stage1/rec/warp` 8, `stage1/rec/wallcrash` 2, `stage1/rec/kb` 2 and 7 more) |
| Called from | `TrailIntro` |
| Calls | `FillColumn`, `SpriteList`, `AttrBoxes`, `ClearTopHalf`, `TrailAttrs` (tail), `ScreenAddrHL`, `JpNextLineHL`, `JpLoadRecordP1`, `JpSaveRecordP1`, `JpShowBars` |
| Writes | `$4000` (screen); `$4017` (screen); `$D6C2` (`HudY`) |

### `Checker` (`$6BDC`)

**A checkered band: B columns of C lines from the position in SpriteX/SpriteY, `$AA` and `$55` by turns**

Witness: L1 11 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 1 call, 736 t-states own (0.00 %) |
| Runs (the other recordings) | 10 calls (`stage1/rec/empty` 1, `stage1/rec/fuel` 1, `stage1/rec/kb` 1 and 7 more) |
| Called from | `LoadIntro` |
| Calls | `CheckerColumn`, `GfxTable` |

### `CheckerColumn` (`$6BEC`)

**One column of the band**

Witness: L1 77 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 7 calls, 645 t-states own (0.00 %) |
| Runs (the other recordings) | 70 calls (`stage1/rec/empty` 7, `stage1/rec/fuel` 7, `stage1/rec/speedcrash` 7 and 7 more) |
| Called from | `Checker` |
| Calls | `FillEveryOther` (falls into), `JpNextLineHL` |

### `FillEveryOther` (`$6BFA`)

**Write E to every other line, C times**

Witness: L1 13552 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 14 calls, 92,897 t-states own (0.01 %) |
| Runs (the other recordings) | 140 calls (`stage1/rec/kb` 14, `stage1/rec/empty` 14, `stage1/rec/fuel` 14 and 7 more) |
| Called from | `CheckerColumn` (falls into) |
| Calls | `JpNextLineHL` |
| Writes | `$4059`-`$50FF` (screen); `$5119`-`$51DF` (screen); `$5219`-`$52DF` (screen); `$5319`-`$53DF` (screen); `$5419`-`$54DF` (screen); `$5519`-`$55DF` (screen); 2 more ranges |

### `PutMenuSprite` (`$6C05`)

**DestAddr = the buffer address of SpriteX / SpriteY; JP MenuSpriteGo**

Witness: L1 6 (c1, menu, trail1, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 2 calls, 106 t-states own (0.00 %) |
| Runs (the other recordings) | 4 calls (`stage1/rec/menu` 2, `stage1/rec/trail1` 1, `stage1/rec/warp` 1) |
| Called from | `SpriteList` |
| Calls | `JpMenuSprite` (tail), `JpBufferAddr` |
| Writes | `$80E5`-`$80E6` (`DestAddr`) |

### `PutGameSprite` (`$6C0E`)

**DestAddr = the buffer address; JP GameSpriteGo**

Witness: L1 24 (c1, menu, trail1, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 8 calls, 480 t-states own (0.00 %) |
| Runs (the other recordings) | 16 calls (`stage1/rec/menu` 8, `stage1/rec/trail1` 4, `stage1/rec/warp` 4) |
| Called from | `SpriteList` |
| Calls | `JpGameSprite` (tail), `JpBufferAddr` |
| Writes | `$80E5`-`$80E6` (`DestAddr`) |

### `SpriteList` (`$6C17`)

**Draw a list of sprites: x, y, sprite number, ending `$FF`**

IX the list. Each item through the routine in SpriteListCall (`$6C2A`, set by the caller to MenuSprite, GameSprite, PutMenuSprite or PutGameSprite).

Witness: L1 241 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 7 calls, 5,425 t-states own (0.00 %) |
| Runs (the other recordings) | 60 calls (`stage1/rec/warp` 19, `stage1/rec/kb` 7, `stage1/rec/wallcrash` 5 and 8 more) |
| Called from | `LoadIntro`, `PanelP2`, `PanelP1`, `ShowHud`, `Credits` |
| Calls | `PutMenuSprite`, `PutGameSprite`, `JpGameSpriteAt`, `JpMenuSpriteAt` |
| Reads | `$6C9E`-`$6CD4` (`PanelP1Sprites`, `PanelP2Sprites`, `HudSprites`, `LoadIntroSprites`); `$6EFC`-`$6F0C` (`CreditSprites1`, `CreditSprites2`) |
| Writes | `$80DB`-`$80E7` (`SpriteX`, `SpriteY`, `ScreenBase`, `DestAddr` and 1 more) |

### `CellCount` (`$6C3A`)

**A = A / 8 + 1 (pixels to attribute cells)**

Witness: L1 777 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 82 calls, 3,735 t-states own (0.00 %) |
| Runs (the other recordings) | 695 calls (`stage1/rec/warp` 231, `stage1/rec/kb` 94, `stage1/rec/trails` 62 and 8 more) |
| Called from | `AttrBoxes`, `InitTextWidths`, `ReadControlRaw` |

### `AttrBoxes` (`$6C43`)

**Colour a list of boxes: x1, y1, x2, y2, attribute; ending `$FF`**

IX the list; each box FillAttrs over (x2-x1)/8+1 columns and (y1-y2)/8+1 rows.

Witness: L1 374 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 6 calls, 7,578 t-states own (0.00 %) |
| Runs (the other recordings) | 76 calls (`stage1/rec/warp` 26, `stage1/rec/kb` 9, `stage1/rec/wallcrash` 7 and 8 more) |
| Called from | `LoadIntro` (tail), `TrailIntro`, `PanelP2`, `PanelP1`, `ShowHud`, `Credits` |
| Calls | `CellCount`, `FillAttrs` |
| Reads | `$6CD5`-`$6D50` (`LoadIntroBoxes`, `PanelP2Boxes`, `PanelP1Boxes`, `HudBoxes`); `$6ED7`-`$6EFB` (`TrailIntroBoxes`, `CreditBoxes`) |

### `ShowHud` (`$6C6F`)

**Zero the clock, draw the HUD's sprites and boxes, the maximum time and the clock**

Witness: L1 21 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 1 call, 280 t-states own (0.00 %) |
| Runs (the other recordings) | 20 calls (`stage1/rec/warp` 8, `stage1/rec/kb` 2, `stage1/rec/wallcrash` 2 and 7 more) |
| Called from | `JpShowHud` (tail) |
| Calls | `SpriteList`, `AttrBoxes`, `JpShowMaxTime` (tail), `JpShowClock` |
| Writes | `$6C2A`-`$6C2B` (`SpriteListCall+1`); `$80DF`-`$80E0` (`ScreenBase`); `$82F8`-`$82F9` (`ModeVector`); `$D6C9`-`$D6CB` (`Clock`, `ClockTens`, `ClockUnits`) |

### `FrameBox` (`$6D51`)

**Draw the frame of a box in the buffer (the menus' frames)**

The buffer address of SpriteX / SpriteY, B the width in pixels, C the height: a top line, C-2 sides (`$0F` ... `$E0`), a bottom line.

Witness: L1 33 (c1, kb, menu, trail1, turn, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 2 calls, 15,204 t-states own (0.00 %) |
| Runs (the other recordings) | 31 calls (`stage1/rec/menu` 25, `stage1/rec/turn` 2, `stage1/rec/warp` 2 and 2 more) |
| Called from | `MenuBoxDraw` (tail) |
| Calls | `FrameLine` (falls into), `FillFF`, `JpBufferAddr` |
| Writes | `$F0C1`-`$F615` (`BufferP1+133`, `BufferP1Zeros`, `Trail6Image`, `BufferP1Byte` and 1 more); `$F626`-`$F62B` (`BufferP1Rest+363`); `$F63C`-`$F641` (`BufferP1Rest+385`); `$F652`-`$F657` (`BufferP1Rest+407`); `$F668`-`$F66D` (`BufferP1Rest+429`); `$F67E`-`$F683` (`BufferP1Rest+451`); 1 more ranges |

### `FrameLine` (`$6D77`)

**A frame's top or bottom line: `$03`, `$FF` bytes, `$C0`**

Witness: L1 66 (c1, kb, menu, trail1, turn, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 4 calls, 254 t-states own (0.00 %) |
| Runs (the other recordings) | 62 calls (`stage1/rec/menu` 50, `stage1/rec/warp` 4, `stage1/rec/turn` 4 and 2 more) |
| Called from | `FrameBox` (falls into) |
| Calls | `FillFF` |
| Writes | `$F0AB` (`BufferP1+111`); `$F0BC` (`BufferP1+128`); `$F329` (`Trail6Image+249`); `$F33A` (`Trail6Image+266`); `$F489` (`Trail6Image+601`); `$F49A` (`Trail6Image+618`); 4 more ranges |

### `FillFF` (`$6D7F`)

**B bytes of `$FF` after HL**

Witness: L1 1902 (c1, kb, menu, trail1, turn, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 124 calls, 78,868 t-states own (0.01 %) |
| Runs (the other recordings) | 1,778 calls (`stage1/rec/menu` 1,470, `stage1/rec/turn` 124, `stage1/rec/warp` 92 and 2 more) |
| Called from | `FrameBox`, `FrameLine` |
| Writes | `$F0AC`-`$F6A9` (`BufferP1+112`, `BufferP1Zeros`, `Trail6Image`, `BufferP1Byte` and 1 more) |

### `Dissolve` (`$6D88`)

**Bring the buffer onto the screen by eight passes of rotating its bits in from the sides**

HL the buffer, DE the screen address. Each pass rotates each line's 22 bytes, the left 11 through RotateLeft and the right through RotateRight, so the picture slides in from both sides, with a delay of `$1E` x 256 loops between passes. Used by the title, the high scores, the menus and the trail intro (c1: 28 calls).

Witness: L1 34 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 7 calls, 10,592,138 t-states own (0.68 %) |
| Runs (the other recordings) | 27 calls (`stage1/rec/warp` 11, `stage1/rec/trail1` 4, `stage1/rec/kb` 2 and 8 more) |
| Called from | `TrailIntro`, `Title`, `HiScoreScreen`, `MenuShowDissolve` |
| Calls | `RotateLeft`, `RotateRight`, `JpNextLineDE` |

### `RotateLeft` (`$6DC1`)

**Rotate a buffer byte left into the screen byte**

Witness: L1 239360 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 49,280 calls, 3,346,499 t-states own (0.21 %) |
| Runs (the other recordings) | 190,080 calls (`stage1/rec/warp` 77,440, `stage1/rec/trail1` 28,160, `stage1/rec/kb` 14,080 and 8 more) |
| Called from | `Dissolve` |
| Reads | `$4081`-`$57FA` (screen); `$F03C`-`$F71B` (`BufferP1`, `BufferP1Zeros`, `Trail6Image`, `BufferP1Byte` and 1 more) |
| Writes | `$4081`-`$57FA` (screen); `$F03C`-`$F71B` (`BufferP1`, `BufferP1Zeros`, `Trail6Image`, `BufferP1Byte` and 1 more) |

### `RotateRight` (`$6DC9`)

**Rotate a buffer byte right into the screen byte**

Witness: L1 239360 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 49,280 calls, 3,004,950 t-states own (0.19 %) |
| Runs (the other recordings) | 190,080 calls (`stage1/rec/warp` 77,440, `stage1/rec/trail1` 28,160, `stage1/rec/kb` 14,080 and 8 more) |
| Called from | `Dissolve` |
| Reads | `$4082`-`$57F9` (screen); `$F03D`-`$F71A` (`BufferP1+1`, `BufferP1Zeros`, `Trail6Image`, `BufferP1Byte` and 1 more) |
| Writes | `$4082`-`$57F9` (screen); `$F03D`-`$F71A` (`BufferP1+1`, `BufferP1Zeros`, `Trail6Image`, `BufferP1Byte` and 1 more) |

### `ClearScreen` (`$6DD1`)

**Border black, clear the screen and its attributes (`$45`), wait for no key, 60 frames**

Also the main menu's START action: the menu returns to NewGame.

Witness: L1 30 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 4 calls, 767 t-states own (0.00 %) |
| Runs (the other recordings) | 15 calls (`stage1/rec/trail1` 3, `stage1/rec/warp` 3, `stage1/rec/kb` 2 and 7 more) |
| Called from | `LoadIntro`, `Title`, `MenuDispatch`, `CheckHiScore` |
| Calls | `WaitKey60` (tail), `ClearPixels`, `FillAttrsBase` |
| Writes | `$8084`-`$808A` (`AttrBase`, `KempstonOn`, `Keyboard1Alt`, `SinclairOn` and 2 more); `$80DF`-`$80E0` (`ScreenBase`) |
| Ports out | `$00FE` |

### `RestoreTunePlayer` (`$6DEF`)

**Copy the tune player from `$5B00` back to `$F850` (no caller; Title and TrailEnd do it inline)**

Known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `Title` (`$6DFB`)

**The title sequence: the credits, the high scores, the menus, the title tune**

Copies TunePlayerCopy (`$5B00`, `$5AB` bytes) back to `$F850`, sets TuneTimer = `$04C8`, then credits (Credits), the high scores (HiScoreScreen), the menu pages; ends in MenuLoop. OuterLoop calls it through MenuTable (`$69A6`, JP Title) (c1: from frame 14 101; the menu at 14 640).

Witness: L1 4 (c1, trail1, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 2 calls, 70,588 t-states own (0.00 %) |
| Runs (the other recordings) | 2 calls (`stage1/rec/trail1` 1, `stage1/rec/warp` 1) |
| Called from | `MenuTable` (tail) |
| Calls | `Dissolve`, `ClearScreen`, `WaitKey60`, `Scroller`, `Credits`, `HiScoreScreen`, `TrailListScreen`, `MenuBox`, `MenuShowDissolve`, `MenuDraw`, `MenuLoop` (tail) |
| Reads | `$5B00`-`$60AA` (system) |
| Writes | `$6724`-`$6726` (`TuneTimer`, `MenuSpare`, `MenuItem`); `$6F0D` (`HiScorePage`); `$F850`-`$FDFA` (`TunePlay0`, `TunePlay`, `TuneLoop`, `TuneInterrupt` and 33 more) |

### `WaitKey60` (`$6E4A`)

**Wait 60 frames or a key or fire (carry set on a key)**

Witness: L1 50 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 15 calls, 30,114,150 t-states own (1.92 %) |
| Runs (the other recordings) | 35 calls (`stage1/rec/warp` 9, `stage1/rec/trail1` 9, `stage1/rec/kb` 3 and 7 more) |
| Called from | `ClearScreen` (tail), `Title` |
| Calls | `AnyKey`, `JpClearKeys`, `GameEntry` |
| Reads | `$6E52` (`l_6E50+2`) |
| Writes | `$EB5A` (`ClockAdd+1`) |

### `Random` (`$6E5C`)

**A byte from the ROM at RandomSeed; L + 3, but H AND `$1B` is taken before INC H, so the pointer stays in its page (`$08`): Noise reads the same 256 ROM bytes over and over**

HL = RandomSeed; H steps through 0-`$1B`, L by one: A = the ROM's byte there. The noise effect (Noise `$D9AF`) is its only caller.

Witness: L1 1690 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 50 calls, 4,730 t-states own (0.00 %) |
| Runs (the other recordings) | 1,640 calls (`stage1/rec/kb` 620, `stage1/rec/warp` 330, `stage1/rec/empty` 230 and 7 more) |
| Called from | `JpRandom` (tail) |
| Reads | `$6E5A`-`$6E5B` (`RandomSeed`) |
| Writes | `$6E5A`-`$6E5B` (`RandomSeed`) |

### `Scroller` (`$6E6C`)

**Scroll the buffer's credits 32 times (the second credit screen)**

Witness: L1 4 (c1, trail1, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 2 calls, 10,102 t-states own (0.00 %) |
| Runs (the other recordings) | 2 calls (`stage1/rec/warp` 1, `stage1/rec/trail1` 1) |
| Called from | `Title` |
| Calls | `ShowBufferAt`, `JpNextLineDE` |

### `Credits` (`$6E81`)

**The credits: the ATV picture, the sprites and boxes, "ALL TERRAIN VEHICLE" and the names**

Witness: L1 6 (c1, menu, trail1, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 2 calls, 992 t-states own (0.00 %) |
| Runs (the other recordings) | 4 calls (`stage1/rec/menu` 2, `stage1/rec/trail1` 1, `stage1/rec/warp` 1) |
| Called from | `Title`, `MenuControl` |
| Calls | `SpriteList`, `AttrBoxes`, `PrintAt`, `FillAttrs`, `ShowBufferPlace` (tail), `JpClearBufferP1` |
| Reads | `$7193` (`MenuTexts+233`) |
| Writes | `$6C2A`-`$6C2B` (`SpriteListCall+1`); `$8144`-`$8145` (`BufferBase`); `$82F8`-`$82F9` (`ModeVector`) |

### `HiScoreScreen` (`$6F0E`)

**Show the high score table (every other time: the trail list)**

Witness: L1 5 (c1, menu, trail1, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 2 calls, 1,477 t-states own (0.00 %) |
| Runs (the other recordings) | 3 calls (`stage1/rec/warp` 1, `stage1/rec/trail1` 1, `stage1/rec/menu` 1) |
| Called from | `Title`, `MenuTick`, `MaskBuffer`, `MaskMirror` |
| Calls | `Dissolve`, `ShowAt284F`, `TrailListScreen`, `HiScoreLines`, `ClearMenuSpare`, `JpGameSprite`, `JpClearBufferP1`, `JpBufferAddr`, `MaskBuffer`, `MaskMirror` |
| Reads | `$6F0D` (`HiScorePage`); `$80E5`-`$80E9` (`DestAddr`, `SpriteNum`, `SpriteData`); `$8371`-`$8374` (`ListModes+4`) |
| Writes | `$6F0D` (`HiScorePage`); `$80DB`-`$80EB` (`SpriteX`, `SpriteY`, `ScreenBase`, `DestAddr` and 3 more); `$8144`-`$8145` (`BufferBase`); `$82F8`-`$82F9` (`ModeVector`) |

### `ShowAt284F` (`$6F8F`)

**DE = the screen address of x `$28`, y `$4F` (the menus' buffer place)**

Witness: L1 5 (c1, menu, trail1, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 2 calls, 109 t-states own (0.00 %) |
| Runs (the other recordings) | 3 calls (`stage1/rec/warp` 1, `stage1/rec/trail1` 1, `stage1/rec/menu` 1) |
| Called from | `HiScoreScreen` |
| Calls | `ScreenAddrHL` |

### `TrailListScreen` (`$6F97`)

**The six trail names in the buffer**

Witness: L1 9 (c1, menu, trail1, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 4 calls, 619 t-states own (0.00 %) |
| Runs (the other recordings) | 5 calls (`stage1/rec/trail1` 2, `stage1/rec/warp` 2, `stage1/rec/menu` 1) |
| Called from | `Title`, `HiScoreScreen` |
| Calls | `TrailListLines`, `ScreenAddrHL`, `JpClearBufferP1` |
| Writes | `$8144`-`$8145` (`BufferBase`) |

### `TrailListLines` (`$6FAB`)

**Print TrailList's lines**

Witness: L1 9 (c1, menu, trail1, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 4 calls, 5,887 t-states own (0.00 %) |
| Runs (the other recordings) | 5 calls (`stage1/rec/warp` 2, `stage1/rec/trail1` 2, `stage1/rec/menu` 1) |
| Called from | `TrailListScreen` |
| Calls | `Print` |
| Reads | `$71A6` (`MenuTexts+252`); `$71C1`-`$71D0` (`MenuTexts+279`); `$71E9`-`$71FA` (`MenuTexts+319`); `$720B`-`$720D` (`MenuTexts+353`, `MenuBox`); `$80DD` (`SpriteY`) |
| Writes | `$80DB`-`$80DD` (`SpriteX`, `SpriteY`); `$82F8`-`$82F9` (`ModeVector`) |

### `ReturnByte` (`$6FE9`)

**A lone RET (no caller)**

Known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `HiScoreLines` (`$6FEA`)

**Print the five names and scores**

Witness: L1 4 (c1, trail1, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 2 calls, 3,443 t-states own (0.00 %) |
| Runs (the other recordings) | 2 calls (`stage1/rec/trail1` 1, `stage1/rec/warp` 1) |
| Called from | `HiScoreScreen` |
| Calls | `Print` |
| Reads | `$80DD` (`SpriteY`) |
| Writes | `$80DB`-`$80DD` (`SpriteX`, `SpriteY`); `$82F8`-`$82F9` (`ModeVector`) |

### `MenuBox` (`$720C`)

**Set the box from a menu (IY): x, y, item count; the line spacing `$10` (or `$0E` for six or more items)**

Witness: L1 37 (c1, kb, menu, trail1, turn, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 4 calls, 648 t-states own (0.00 %) |
| Runs (the other recordings) | 33 calls (`stage1/rec/menu` 25, `stage1/rec/warp` 3, `stage1/rec/trail1` 2 and 2 more) |
| Called from | `Title`, `MenuDraw` |
| Reads | `$702A`-`$7064` (`MenuDefs`, `MenuControls1`, `MenuControls2a`, `MenuControls2` and 1 more); `$707E`-`$7080` (`MenuKeys2`); `$709A`-`$70A4` (`MenuPlayerOne`, `MenuPlayerTwo`) |
| Writes | `$6720`-`$6723` (`MenuVars`, `MenuBoxY`, `MenuBoxHeight`, `MenuCount`); `$72C5` (`LineSpacing`) |

### `MenuBoxDraw` (`$723B`)

**Clear the buffer and draw the menu's frame**

Witness: L1 33 (c1, kb, menu, trail1, turn, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 2 calls, 430 t-states own (0.00 %) |
| Runs (the other recordings) | 31 calls (`stage1/rec/menu` 25, `stage1/rec/warp` 2, `stage1/rec/turn` 2 and 2 more) |
| Called from | `MenuDraw` |
| Calls | `FrameBox` (tail), `JpClearBufferP1` |
| Reads | `$6722` (`MenuBoxHeight`) |
| Writes | `$80DB`-`$80DD` (`SpriteX`, `SpriteY`); `$8144`-`$8145` (`BufferBase`) |

### `MenuBoxFrame` (`$725F`)

**The frame (FrameBox) at the box's place**

Witness: L1 33 (c1, kb, menu, trail1, turn, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 2 calls, 380 t-states own (0.00 %) |
| Runs (the other recordings) | 31 calls (`stage1/rec/menu` 25, `stage1/rec/warp` 2, `stage1/rec/turn` 2 and 2 more) |
| Called from | `MenuDraw` (tail) |
| Calls | `FillAttrs` (tail) |
| Reads | `$6720`-`$6722` (`MenuVars`, `MenuBoxY`, `MenuBoxHeight`); `$702D`-`$7065` (`MenuDefs+3`, `MenuControls1`, `MenuControls2a`, `MenuControls2` and 1 more); `$7081` (`MenuKeys2+3`); `$709D`-`$70A5` (`MenuPlayerOne+3`, `MenuPlayerTwo`) |

### `MenuBoxClear` (`$728C`)

**Clear the box's attributes**

Witness: L1 5 (menu, turn).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 5 calls (`stage1/rec/menu` 4, `stage1/rec/turn` 1) |
| Called from | `MenuControl` |
| Calls | `FillAttrs` |
| Reads | `$6720`-`$6721` (`MenuVars`, `MenuBoxY`); `$729D` (`MenuBoxClear+17`) |

### `MenuShowDissolve` (`$729E`)

**The box into the screen by Dissolve**

Witness: L1 4 (c1, trail1, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 2 calls, 108 t-states own (0.00 %) |
| Runs (the other recordings) | 2 calls (`stage1/rec/trail1` 1, `stage1/rec/warp` 1) |
| Called from | `Title` |
| Calls | `Dissolve`, `MenuBoxScreen` |

### `MenuShow` (`$72A8`)

**The box into the screen by ShowBuffer**

Witness: L1 27 (kb, menu, turn, warp).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 27 calls (`stage1/rec/menu` 23, `stage1/rec/turn` 2, `stage1/rec/kb` 1 and 1 more) |
| Called from | `MenuRedraw` (tail), `MenuOpen`, `MenuMain` |
| Calls | `MenuBoxScreen`, `ShowBufferAt` (tail) |
| Reads | `$72AC` (`MenuShow+4`) |

### `MenuBoxScreen` (`$72B2`)

**DE = the screen address of the box**

Witness: L1 31 (c1, kb, menu, trail1, turn, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 2 calls, 180 t-states own (0.00 %) |
| Runs (the other recordings) | 29 calls (`stage1/rec/menu` 23, `stage1/rec/warp` 2, `stage1/rec/turn` 2 and 2 more) |
| Called from | `MenuShowDissolve`, `MenuShow` |
| Calls | `GfxTable` |
| Reads | `$6720`-`$6721` (`MenuVars`, `MenuBoxY`) |
| Writes | `$80DB`-`$80DD` (`SpriteX`, `SpriteY`) |

### `MenuItems` (`$72C6`)

**Print the menu's item texts, one under another**

Witness: L1 33 (c1, kb, menu, trail1, turn, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 2 calls, 2,160 t-states own (0.00 %) |
| Runs (the other recordings) | 31 calls (`stage1/rec/menu` 25, `stage1/rec/turn` 2, `stage1/rec/warp` 2 and 2 more) |
| Called from | `MenuDraw` |
| Calls | `Print` |
| Reads | `$702A`-`$70B9` (`MenuDefs`, `MenuTexts`); `$70CA`-`$7183` (`MenuTexts+32`); `$72C5` (`LineSpacing`); `$80DB`-`$80DD` (`SpriteX`, `SpriteY`) |
| Writes | `$80DB`-`$80DD` (`SpriteX`, `SpriteY`); `$8144`-`$8145` (`BufferBase`); `$82F8`-`$82F9` (`ModeVector`) |

### `MenuRedraw` (`$7320`)

**Draw the menu (MenuDraw) and show it**

Witness: L1 19 (kb, menu, warp).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 19 calls (`stage1/rec/menu` 17, `stage1/rec/kb` 1, `stage1/rec/warp` 1) |
| Called from | `MenuControl`, `MenuKeys2Select`, `RedefineKey`, `MenuPlayers`, `NameEntry` |
| Calls | `MenuShow` (tail), `MenuDraw` |

### `MenuOpen` (`$7326`)

**Draw a menu, show it and run the menu loop again**

Witness: L1 5 (menu, turn).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 5 calls (`stage1/rec/menu` 4, `stage1/rec/turn` 1) |
| Called from | `MenuControl` |
| Calls | `MenuShow`, `MenuDraw`, `MenuLoop` (tail) |

### `MenuDraw` (`$732F`)

**The box, the frame and the items of the menu at IY**

Witness: L1 33 (c1, kb, menu, trail1, turn, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 2 calls, 162 t-states own (0.00 %) |
| Runs (the other recordings) | 31 calls (`stage1/rec/menu` 25, `stage1/rec/warp` 2, `stage1/rec/turn` 2 and 2 more) |
| Called from | `Title`, `MenuRedraw`, `MenuOpen`, `MenuMain`, `MenuKeys2Select` |
| Calls | `MenuBox`, `MenuBoxDraw`, `MenuBoxFrame` (tail), `MenuItems` |
| Writes | `$80DD` (`SpriteY`) |

### `MenuTick` (`$7340`)

**The title tune's interrupt hook: count TuneTimer, run the menu**

TuneHook calls it every frame while the title tune plays (c1: 5388 runs); it counts TuneTimer (MenuTimer), checks the keys and returns to the tune player.

Witness: L1 5421 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 1,517 calls, 155,315 t-states own (0.01 %) |
| Runs (the other recordings) | 3,904 calls (`stage1/rec/menu` 2,560, `stage1/rec/trail1` 800, `stage1/rec/warp` 508 and 8 more) |
| Called from | `TuneInterrupt` |
| Calls | `HiScoreScreen`, `MenuTimer`, `TuneKeyCheck` (tail) |
| Reads | `$8086` (`KempstonOn`) |
| Ports in | `$001F` |

### `MenuTimer` (`$7368`)

**TuneTimer + 1; Z when its low byte wraps**

Witness: L1 5871 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 1,518 calls, 91,562 t-states own (0.01 %) |
| Runs (the other recordings) | 4,353 calls (`stage1/rec/menu` 2,868, `stage1/rec/trail1` 801, `stage1/rec/warp` 509 and 8 more) |
| Called from | `MenuTick`, `MenuLoop` |
| Reads | `$6724`-`$6725` (`TuneTimer`, `MenuSpare`) |
| Writes | `$6724`-`$6725` (`TuneTimer`, `MenuSpare`) |

### `WaitNoKey` (`$7373`)

**Wait until no key and no fire**

Witness: L1 71072 (c1, menu, trail1, turn, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 2 calls, 1,019,549 t-states own (0.07 %) |
| Runs (the other recordings) | 23 calls (`stage1/rec/menu` 15, `stage1/rec/turn` 6, `stage1/rec/trail1` 1 and 1 more) |
| Called from | `MenuLoop` |
| Calls | `AnyKey`, `JpClearKeys` |

### `MenuLoop` (`$737C`)

**The menu: highlight, the title tune, keys up and down, select**

Starts TunePlay with tune 0 and TuneHook = MenuTick; after a key stops it, the loop moves the highlight (any key the next item), SPACE/fire selects (MenuDispatch); TuneTimer reaching `$8000` goes back to Title, `$0400` to the high scores.

Witness: L1 7 (c1, menu, trail1, turn, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 2 calls, 64,467 t-states own (0.00 %) |
| Runs (the other recordings) | 5 calls (`stage1/rec/menu` 2, `stage1/rec/turn` 1, `stage1/rec/warp` 1 and 1 more) |
| Called from | `Title` (tail), `MenuOpen` (tail), `MenuMain` (tail), `MenuKeys2Select` (tail), `MenuPlayers` (tail), `TuneKeyCheck` |
| Calls | `MenuTimer`, `WaitNoKey`, `ClearMenuSpare`, `AnyKey`, `SelectKey`, `Highlight`, `MenuDispatch` (tail), `JpClearKeys`, `JpSetupIm2`, `TunePlay` |
| Reads | `$6723`-`$6726` (`MenuCount`, `TuneTimer`, `MenuSpare`, `MenuItem`); `$73B6` (`l_73B5+1`); `$73E8`-`$73EA` (`l_73D3+21`) |
| Writes | `$6726` (`MenuItem`); `$F96D`-`$F96E` (`TuneHook+1`) |

### `ClearMenuSpare` (`$73FD`)

**MenuSpare (`$6725`) = 0: a byte written here and read by no one**

Witness: L1 42 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 3 calls, 81 t-states own (0.00 %) |
| Runs (the other recordings) | 39 calls (`stage1/rec/menu` 20, `stage1/rec/turn` 8, `stage1/rec/trail1` 2 and 8 more) |
| Called from | `HiScoreScreen`, `MenuLoop` |
| Writes | `$6725` (`MenuSpare`) |

### `AnyKey` (`$7402`)

**Carry when any key or the Kempston's fire is down**

Witness: L1 77347 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 16,574 calls, 32,853,949 t-states own (2.10 %) |
| Runs (the other recordings) | 60,773 calls (`stage1/rec/trail1` 54,994, `stage1/rec/menu` 4,256, `stage1/rec/warp` 483 and 8 more) |
| Called from | `WaitKey60`, `WaitNoKey`, `MenuLoop`, `ReadNewKey` |
| Calls | `JpScanKeys` |
| Reads | `$8086`-`$80B2` (`KempstonOn`, `Keyboard1Alt`, `SinclairOn`, `JoyBits` and 2 more) |

### `SelectKey` (`$741F`)

**Carry when SPACE, 0 or the Kempston's fire is down (ENTER is not read here: it moves)**

Witness: L1 32 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 1 call, 31 t-states own (0.00 %) |
| Runs (the other recordings) | 31 calls (`stage1/rec/menu` 15, `stage1/rec/turn` 7, `stage1/rec/empty` 1 and 8 more) |
| Called from | `MenuLoop` |
| Reads | `$8086`-`$8089` (`KempstonOn`, `Keyboard1Alt`, `SinclairOn`, `JoyBits`); `$809F`-`$80AE` (`KeyStates+20`) |

### `Highlight` (`$7439`)

**Colour the current item's line with A**

Witness: L1 45 (c1, menu, trail1, turn, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 2 calls, 610 t-states own (0.00 %) |
| Runs (the other recordings) | 43 calls (`stage1/rec/menu` 31, `stage1/rec/turn` 10, `stage1/rec/warp` 1 and 1 more) |
| Called from | `MenuLoop`, `RedefineKey` |
| Calls | `ItemPtr`, `FillAttrs`, `JpMultiply` |
| Reads | `$6720`-`$6726` (`MenuVars`, `MenuBoxY`, `MenuBoxHeight`, `MenuCount` and 3 more); `$70AA`-`$716E` (`MenuTexts`); `$72C5` (`LineSpacing`) |

### `ItemPtr` (`$746D`)

**IX = the current item's place in the menu (IY): HL its text**

Witness: L1 78 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 3 calls, 539 t-states own (0.00 %) |
| Runs (the other recordings) | 75 calls (`stage1/rec/menu` 51, `stage1/rec/turn` 13, `stage1/rec/warp` 2 and 8 more) |
| Called from | `Highlight`, `MenuDispatch`, `RedefineKey`, `MenuPlayers` |
| Reads | `$6726` (`MenuItem`); `$702E`-`$7097` (`MenuDefs+4`, `MenuControls1`, `MenuControls2a`, `MenuControls2` and 2 more) |

### `MenuDispatch` (`$7489`)

**Jump to the current item's action**

Witness: L1 22 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 1 call, 59 t-states own (0.00 %) |
| Runs (the other recordings) | 21 calls (`stage1/rec/menu` 9, `stage1/rec/turn` 3, `stage1/rec/empty` 1 and 8 more) |
| Called from | `MenuLoop` (tail) |
| Calls | `ClearScreen`, `ItemPtr`, `MenuControl`, `MenuKeys1Select`, `MenuKeys2Select`, `MenuPlayers`, `ChooseKempston`, `ChooseKeys1`, `ChooseSinclair` |
| Reads | `$7030`-`$7061` (`MenuDefs+6`, `MenuControls1`, `MenuControls2a`, `MenuControls2`); `$707C`-`$707D` (`MenuKeys1+26`); `$7098`-`$7099` (`MenuKeys2+26`) |

### `MenuMain` (`$7493`)

**Show the main menu again**

Witness: L1 3 (menu, turn).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 3 runs of its first instruction, entered by a jump (`stage1/rec/menu` 2, `stage1/rec/turn` 1) |
| Calls | `MenuShow`, `MenuDraw`, `MenuLoop` (tail) |

### `MenuControl` (`$74A4`)

**CHOOSE CONTROL: one player's menu, or both players' in turn**

Witness: L1 3 (menu, turn).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 3 runs of its first instruction, entered by a jump (`stage1/rec/menu` 2, `stage1/rec/turn` 1) |
| Called from | `MenuDispatch` |
| Calls | `Credits`, `MenuBoxClear`, `MenuRedraw`, `MenuOpen` |
| Reads | `$6947` (`PlayerVars`) |
| Writes | `$6726` (`MenuItem`); `$6947` (`PlayerVars`) |

### `MenuKeys1Select` (`$74EA`)

**Player 1's keyboard: Kempston off, redefine**

Witness: L1 1 (menu).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 1 run of its first instruction, entered by a jump (`stage1/rec/menu` 1) |
| Called from | `MenuDispatch` |
| Calls | `MenuKeys2Select` (tail) |
| Writes | `$8086`-`$8087` (`KempstonOn`, `Keyboard1Alt`) |

### `MenuKeys2Select` (`$74F7`)

**Player 2's keyboard: Sinclair off, redefine**

Witness: L1 1 (menu).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 1 run of its first instruction, entered by a jump (`stage1/rec/menu` 1) |
| Called from | `MenuDispatch`, `MenuKeys1Select` (tail) |
| Calls | `MenuRedraw`, `MenuDraw`, `MenuLoop` (tail), `RedefineKey` |
| Reads | `$6726` (`MenuItem`) |
| Writes | `$6726` (`MenuItem`); `$8088` (`SinclairOn`) |

### `RedefineKey` (`$751F`)

**Highlight a key's line, wait for a key, store it, print it**

Witness: L1 10 (menu).

[Animation: `RedefineKey` at work](img/routines/RedefineKey.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 10 calls (`stage1/rec/menu` 10) |
| Called from | `MenuKeys2Select` |
| Calls | `MenuRedraw`, `Highlight`, `ItemPtr`, `ReadNewKey`, `KeySlot` |
| Reads | `$7107`-`$7175` (`MenuTexts+93`) |
| Writes | `$710D`-`$7174` (`MenuTexts+99`); `$8109`-`$8112` (`KeyIndexes1`, `KeyIndexes2`) |

### `ReadNewKey` (`$7542`)

**Wait for a key: its index in KeyStates (0-39); any key is taken, even one already in use (no comparison with the table)**

Witness: L1 10 (menu).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 10 calls (`stage1/rec/menu` 10) |
| Called from | `RedefineKey` |
| Calls | `AnyKey`, `JpClearKeys` |
| Reads | `$80B8`-`$80DA` (`KeyChars+5`) |

### `KeySlot` (`$7563`)

**HL = the player's key slot for the current item (KeyIndexes)**

Witness: L1 10 (menu).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 10 calls (`stage1/rec/menu` 10) |
| Called from | `RedefineKey` |
| Calls | `JpMultiply` |
| Reads | `$6726` (`MenuItem`); `$6947` (`PlayerVars`) |

### `MenuPlayers` (`$7583`)

**ONE / TWO PLAYERS: toggle PlayerCount and the item's text**

Witness: L1 1 (menu).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 1 run of its first instruction, entered by a jump (`stage1/rec/menu` 1) |
| Called from | `MenuDispatch` |
| Calls | `MenuRedraw`, `MenuLoop` (tail), `ItemPtr` |
| Reads | `$6947` (`PlayerVars`); `$7581`-`$7582` (`PlayerTexts+2`) |
| Writes | `$6947` (`PlayerVars`); `$7032`-`$7033` (`MenuDefs+8`) |

### `ChooseKempston` (`$75A7`)

**Player 1: Kempston on**

Witness: L1 1 (menu).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 1 run of its first instruction, entered by a jump (`stage1/rec/menu` 1) |
| Called from | `MenuDispatch` |
| Writes | `$8086` (`KempstonOn`) |

### `ChooseKeys1` (`$75AD`)

**Set Keyboard1Alt `$8087` (the one-player method window's SINCLAIR line)**

Player 1's reader never tests Keyboard1Alt: no effect, KempstonOn stays set. Witness: turn (work/stage1/rec/turn, log.json: alt 1, the ATV still on the Kempston).

Known only from the code.

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 1 run of its first instruction, entered by a jump (`stage1/rec/turn` 1) |
| Called from | `MenuDispatch` |
| Writes | `$8087` (`Keyboard1Alt`) |

### `ChooseSinclair` (`$75B3`)

**Player 2: Sinclair on**

Witness: L1 1 (menu).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 1 run of its first instruction, entered by a jump (`stage1/rec/menu` 1) |
| Called from | `MenuDispatch` |
| Writes | `$8088` (`SinclairOn`) |

### `ShowBufferAt` (`$75B9`)

**HALT, copy the buffer (HL) to the screen (DE), `$6E0` bytes**

Witness: L1 188 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 67 calls, 1,761,294 t-states own (0.11 %) |
| Runs (the other recordings) | 121 calls (`stage1/rec/warp` 46, `stage1/rec/trail1` 34, `stage1/rec/menu` 25 and 8 more) |
| Called from | `Scroller`, `MenuShow` (tail), `ShowBufferPlace` (tail) |
| Calls | `JpCopyLines` (tail) |
| Reads | `$75BA` (`ShowBufferAt+1`) |

### `InitTextWidths` (`$75C0`)

**Measure each of MenuTexts and store its centring offset and width**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 1 call, 7,917 t-states own (0.00 %) |
| Called from | `JpInitTextWidths` (tail) |
| Calls | `CellCount`, `Print` |
| Reads | `$70AA`-`$70B9` (`MenuTexts`); `$70CA`-`$7190` (`MenuTexts+32`); `$71A6` (`MenuTexts+252`); `$71C1`-`$71CE` (`MenuTexts+279`); `$71E9`-`$71F8` (`MenuTexts+319`); `$720B` (`MenuTexts+353`); 1 more ranges |
| Writes | `$70AA`-`$7191` (`MenuTexts`); `$71A6`-`$71A7` (`MenuTexts+252`); `$71C1`-`$71CF` (`MenuTexts+279`); `$71E9`-`$71F9` (`MenuTexts+319`); `$80DB`-`$80DD` (`SpriteX`, `SpriteY`); `$82F8`-`$82F9` (`ModeVector`) |

### `PrintAt` (`$7600`)

**Print at H = x, L = y**

Witness: L1 165 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 9 calls, 381 t-states own (0.00 %) |
| Runs (the other recordings) | 156 calls (`stage1/rec/warp` 66, `stage1/rec/kb` 17, `stage1/rec/trails` 14 and 8 more) |
| Called from | `TrailIntro`, `Credits`, `NameScreen` |
| Calls | `Print` (falls into) |
| Reads | `$6968`-`$6969` (`BigChar`); `$79E6`-`$79FB` (`TrailTexts`, `TrailNameSlot`); `$80DB` (`SpriteX`); `$80F6` (`SpriteAdvance`) |
| Writes | `$80DB`-`$80E7` (`SpriteX`, `SpriteY`, `ScreenBase`, `DestAddr` and 1 more) |

### `Print` (`$7608`)

**Print the text at IX up to |, through the current draw mode**

" " moves 6 pixels, "]" moves to x `$78`, " ! . are glyphs `$5B`, `$56`, `$6F`; digits are big sprites `$99-$A2` (the buffer's line above), a-j sprites `$8D-$96`, letters A-Z sprites `$1E-$37`. Each character's advance + 2.

Witness: L1 36592 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 83 calls, 344,094 t-states own (0.02 %) |
| Runs (the other recordings) | 2,721 calls (`stage1/rec/trails` 1,626, `stage1/rec/warp` 552, `stage1/rec/empty` 173 and 5 more) |
| Called from | `JpPrint` (tail), `TrailListLines`, `HiScoreLines`, `MenuItems`, `InitTextWidths`, `PrintAt` (falls into), `NameEntry` |
| Calls | `JpGameSprite`, `JpBufferAddr` |
| Reads | `$695F`-`$69A5` (`HiScoreTitle`, `HiNames`, `HiScores`); `$70AC`-`$720A` (`MenuTexts+2`); `$79E6`-`$79FB` (`TrailTexts`, `TrailNameSlot`); `$80DB` (`SpriteX`); `$80F6` (`SpriteAdvance`); `$EC4E`-`$EC7E` (`GameTexts`, `OutOfFuelText`, `ExtendedText`, `LapText`) |
| Writes | `$80DB`-`$80E7` (`SpriteX`, `SpriteY`, `ScreenBase`, `DestAddr` and 1 more) |

### `FillAttrs` (`$767D`)

**Fill a box of attributes: A the byte, H/L the x/y, B columns, C rows**

Witness: L1 627 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 40 calls, 182,060 t-states own (0.01 %) |
| Runs (the other recordings) | 587 calls (`stage1/rec/warp` 190, `stage1/rec/menu` 97, `stage1/rec/kb` 64 and 8 more) |
| Called from | `JpFillAttrs` (tail), `AttrBoxes`, `Credits`, `MenuBoxFrame` (tail), `MenuBoxClear`, `Highlight`, `FillAllAttrs` (tail), `TrailAttrs`, `NameCursor` (tail), `NameScreen` |
| Calls | `AttrAddr` |
| Reads | `$808A` (`FillByte`) |
| Writes | `$5800`-`$5AF9` (screen); `$808A` (`FillByte`); `$80DB`-`$80DD` (`SpriteX`, `SpriteY`) |

### `AttrAddr` (`$769E`)

**HL = the attribute address of SpriteX / SpriteY (AttrBase)**

Witness: L1 2766 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 94 calls, 19,435 t-states own (0.00 %) |
| Runs (the other recordings) | 2,672 calls (`stage1/rec/warp` 831, `stage1/rec/trails` 571, `stage1/rec/kb` 348 and 8 more) |
| Called from | `FillAttrs`, `MenuSpriteAttrs` |
| Reads | `$8084`-`$8085` (`AttrBase`); `$80DB`-`$80DD` (`SpriteX`, `SpriteY`) |

### `PixelMask` (`$76C5`)

**A = the bit of SpriteX within its byte**

Witness: L1 26704 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 2,400 calls, 415,874 t-states own (0.03 %) |
| Runs (the other recordings) | 24,304 calls (`stage1/rec/kb` 6,504, `stage1/rec/fuel` 5,016, `stage1/rec/trails` 3,684 and 7 more) |
| Called from | `JpPixelMask` (tail) |
| Reads | `$80DB` (`SpriteX`) |

### `ModeNone` (`$76D3`)

**Draw mode 0: RET (measure only)**

Witness: L1 117549 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 7,710 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 91,617 t-states own (0.01 %) |
| Runs (the other recordings) | 109,839 runs of its first instruction, entered by a jump (`stage1/rec/kb` 31,585, `stage1/rec/fuel` 22,773, `stage1/rec/warp` 18,270 and 7 more) |
| Called from | `SpriteHeader` |

### `ModeOrScreen` (`$76D4`)

**OR a sprite onto the screen (no mode word picks it)**

Known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ModeCopyScreen` (`$76F3`)

**Copy a sprite onto the screen**

Witness: L1 6606 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 682 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 845,777 t-states own (0.05 %) |
| Runs (the other recordings) | 5,924 runs of its first instruction, entered by a jump (`stage1/rec/fuel` 1,270, `stage1/rec/warp` 1,061, `stage1/rec/trails` 1,047 and 7 more) |
| Called from | `SpriteHeader` |
| Calls | `JpNextLineDE` |
| Reads | `$6378`-`$6418` (`MenuGfx+64`); `$643B`-`$6479` (`MenuGfx+259`); `$648E`-`$64F3` (`MenuGfx+342`); `$6538`-`$65D6` (`MenuGfx+512`); `$80E5`-`$80F3` (`DestAddr`, `SpriteNum`, `SpriteData`, `MaskData` and 2 more); `$C9C1`-`$CC6E` (`GameGfx+14949`) |
| Writes | `$4059`-`$52F1` (screen); `$5319`-`$53F1` (screen); `$5419`-`$54F1` (screen); `$5519`-`$55F1` (screen); `$5619`-`$56F1` (screen); `$5719`-`$573E` (screen); 1 more ranges |

### `ModeXorScreen` (`$7711`)

**XOR a sprite onto the screen**

Witness: L1 10292 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 52 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 82,318 t-states own (0.01 %) |
| Runs (the other recordings) | 10,240 runs of its first instruction, entered by a jump (`stage1/rec/warp` 7,436, `stage1/rec/kb` 1,456, `stage1/rec/trails` 760 and 7 more) |
| Called from | `SpriteHeader` |
| Reads | `$40BA`-`$42BE` (screen); `$449A`-`$513E` (screen); `$523B`-`$523E` (screen); `$541B`-`$541E` (screen); `$551B`-`$551E` (screen); `$561B`-`$561E` (screen); 5 more ranges |
| Writes | `$40BA`-`$42BE` (screen); `$449A`-`$513E` (screen); `$523B`-`$523E` (screen); `$541B`-`$541E` (screen); `$551B`-`$551E` (screen); `$561B`-`$561E` (screen); 1 more ranges |

### `MenuSpriteAttrs` (`$773D`)

**Read the attributes of a menu picture (MenuGfx): AttrSrc, AttrWidth, AttrHeight; call the attribute mode**

Witness: L1 2139 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 54 calls, 20,541 t-states own (0.00 %) |
| Runs (the other recordings) | 2,085 calls (`stage1/rec/warp` 641, `stage1/rec/trails` 531, `stage1/rec/kb` 284 and 7 more) |
| Called from | `JpMenuSpriteAttrs` (tail) |
| Calls | `AttrAddr`, `ModeAttrsNone` |
| Reads | `$6338` (`MenuGfx`); `$634A`-`$6373` (`MenuGfx+18`); `$6514`-`$6515` (`MenuGfx+476`); `$652A`-`$652B` (`MenuGfx+498`); `$65EE`-`$65EF` (`MenuGfx+694`); `$6604`-`$6605` (`MenuGfx+716`); 5 more ranges |
| Writes | `$80F7`-`$80FC` (`AttrDest`, `AttrSrc`, `AttrWidth`, `AttrHeight`) |

### `ModeAttrsNone` (`$777A`)

**RET**

Witness: L1 2139 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 54 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 613 t-states own (0.00 %) |
| Runs (the other recordings) | 2,085 runs of its first instruction, entered by a jump (`stage1/rec/warp` 641, `stage1/rec/trails` 531, `stage1/rec/kb` 284 and 7 more) |
| Called from | `MenuSpriteAttrs` |

### `ModeAttrsCopy` (`$777B`)

**Copy a picture's attributes (no mode word picks it)**

Known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ClearPixels` (`$779C`)

**Clear the screen's pixels**

Witness: L1 30 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 5 calls, 832,075 t-states own (0.05 %) |
| Runs (the other recordings) | 25 calls (`stage1/rec/trail1` 4, `stage1/rec/warp` 4, `stage1/rec/kb` 3 and 7 more) |
| Called from | `ClearScreen` |
| Reads | `$4000`-`$57FE` (screen) |
| Writes | `$4000`-`$57FF` (screen) |

### `ClearTopHalf` (`$77AA`)

**Clear the screen's top half (96 lines)**

Witness: L1 42 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 2 calls, 60 t-states own (0.00 %) |
| Runs (the other recordings) | 40 calls (`stage1/rec/warp` 16, `stage1/rec/kb` 4, `stage1/rec/trails` 4 and 7 more) |
| Called from | `TrailIntro`, `PanelP1` |
| Calls | `ClearBottomHalf` (tail) |

### `ClearBottomHalf` (`$77B3`)

**Clear the lower half**

Witness: L1 23 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 1 call, 220,895 t-states own (0.01 %) |
| Runs (the other recordings) | 22 calls (`stage1/rec/warp` 8, `stage1/rec/kb` 4, `stage1/rec/trails` 2 and 7 more) |
| Called from | `TrailIntro`, `PanelP2`, `ClearTopHalf` (tail) |
| Calls | `ScreenAddrHL`, `JpNextLineHL` |
| Reads | `$4000`-`$57F7` (screen) |
| Writes | `$4000`-`$57F8` (screen) |

### `FillAllAttrs` (`$77D2`)

**Fill all 24 attribute rows with A**

Witness: L1 42 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 2 calls, 141 t-states own (0.00 %) |
| Runs (the other recordings) | 40 calls (`stage1/rec/warp` 16, `stage1/rec/wallcrash` 4, `stage1/rec/kb` 4 and 7 more) |
| Called from | `TrailIntro` |
| Calls | `FillAttrs` (tail) |

### `FillAttrsBase` (`$77DB`)

**Fill the 768 attributes at AttrBase with A**

Witness: L1 32 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 5 calls, 106,452 t-states own (0.01 %) |
| Runs (the other recordings) | 27 calls (`stage1/rec/warp` 5, `stage1/rec/kb` 4, `stage1/rec/trail1` 4 and 7 more) |
| Called from | `ClearScreen`, `NameEntry` |
| Reads | `$5800`-`$5AFE` (screen); `$8084`-`$8085` (`AttrBase`) |
| Writes | `$5800`-`$5AFF` (screen) |

### `DetectKempston` (`$77EA`)

**KempstonOn = 1 unless one of 255 reads of port 31 gives all five bits set (no interface: the bus floats to `$FF`)**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 1 call, 16,728 t-states own (0.00 %) |
| Called from | `JpDetectKempston` (tail) |
| Writes | `$8086` (`KempstonOn`) |
| Ports in | `$001F` |

### `BuildRowAddrs` (`$7803`)

**Fill RowAddrs with the 192 lines' screen addresses**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 1 call, 18,318 t-states own (0.00 %) |
| Called from | `JpBuildRowAddrs` (tail) |
| Calls | `JpNextLineHL` |
| Writes | `$6727`-`$68A6` (`RowAddrs`) |

### `ModeCopyBuffer` (`$7817`)

**Copy a sprite into the buffer (22 bytes a line)**

Witness: L1 12838 (c1, empty, kb, trail1, trails, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 7 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 8,305 t-states own (0.00 %) |
| Runs (the other recordings) | 12,831 runs of its first instruction, entered by a jump (`stage1/rec/trails` 8,866, `stage1/rec/warp` 2,383, `stage1/rec/empty` 747 and 3 more) |
| Called from | `SpriteHeader` |
| Reads | `$80E5`-`$80F3` (`DestAddr`, `SpriteNum`, `SpriteData`, `MaskData` and 2 more); `$9DD1`-`$9DDC` (`GameGfx+3701`); `$9E01`-`$9E2C` (`GameGfx+3749`); `$9E51`-`$9ECC` (`GameGfx+3829`); `$9F01`-`$9F1C` (`GameGfx+4005`); `$9F41`-`$9F5C` (`GameGfx+4069`); 2 more ranges |
| Writes | `$F107`-`$F1C1` (`BufferP1Zeros+6`); `$F1FB`-`$F2E0` (`BufferP1Zeros+250`, `Trail6Image`); `$F7E8`-`$F8A1` (`BufferP2+204`, `TunePlay0`, `TunePlay`); `$F939`-`$F9C0` (`l_F916+35`, `TuneInterrupt`, `TuneKeyCheck`, `ChannelBCommand` and 5 more) |

### `ModeXorBuffer` (`$7837`)

**XOR a sprite into the buffer**

Witness: L1 8469 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 158 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 473,932 t-states own (0.03 %) |
| Runs (the other recordings) | 8,311 runs of its first instruction, entered by a jump (`stage1/rec/kb` 2,669, `stage1/rec/trails` 1,548, `stage1/rec/trail1` 1,144 and 8 more) |
| Called from | `SpriteHeader`, `Wheels` |
| Calls | `Wheels` |
| Reads | `$6378`-`$6418` (`MenuGfx+64`); `$80E5`-`$80F3` (`DestAddr`, `SpriteNum`, `SpriteData`, `MaskData` and 2 more); `$9DD1`-`$9F6C` (`GameGfx+3701`); `$A30D`-`$A428` (`GameGfx+5041`); `$AC6B`-`$ACB0` (`GameGfx+7439`); `$BDCB`-`$BE10` (`GameGfx+11887`); 3 more ranges |
| Writes | `$F080`-`$F6E6` (`BufferP1+68`, `BufferP1Zeros`, `Trail6Image`, `BufferP1Byte` and 1 more); `$FA11` (`l_FA10+1`); `$FA29`-`$FB71` (`Drums`, `DrumPad`, `DrumJump2`, `DrumJump3` and 17 more); `$FB8E`-`$FBC5` (`NoteTable+28`, `TuneTable`, `SequencesA0`); `$FBE8`-`$FBEB` (`SequencesA0+46`); `$FC28`-`$FC29` (`SequencesA0+110`); 8 more ranges |

### `BuildBufferRows` (`$7859`)

**Fill BufferRows: 80 offsets of 22**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 1 call, 9,228 t-states own (0.00 %) |
| Called from | `JpBuildBufferRows` (tail) |
| Writes | `$68A7`-`$6946` (`BufferRows`) |

### `InitListWidths` (`$7873`)

**Fill both trail lists' item heights and advances from the sprites**

For each item of TrailListA and TrailListB: the sprite header (through the item's animation record when flags bits 3-7 are set); +2 (y) becomes the height when 0, +3 the advance. Before each trail (c1: 15 runs).

Witness: L1 21 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 1 call, 49 t-states own (0.00 %) |
| Runs (the other recordings) | 20 calls (`stage1/rec/warp` 8, `stage1/rec/trails` 2, `stage1/rec/kb` 2 and 7 more) |
| Called from | `JpInitListWidths` (tail) |
| Calls | `InitList` (falls into) |
| Reads | `$D6B6`-`$D6B9` (`LoopVars`, `TrailListB`) |

### `InitList` (`$787C`)

**One list (HL)**

Witness: L1 42 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 2 calls, 10,700 t-states own (0.00 %) |
| Runs (the other recordings) | 40 calls (`stage1/rec/warp` 16, `stage1/rec/trails` 4, `stage1/rec/wallcrash` 4 and 7 more) |
| Called from | `InitListWidths` (falls into) |
| Calls | `JpSpriteGo` |
| Reads | `$60B4`-`$6299` (system); `$7CB6`-`$8071` (`Trail1ListA+2`, `Trail2ListA`, `Trail3ListA`, `Trail4ListA` and 5 more); `$80F3`-`$80F6` (`SpriteHeight`, `ShiftPtr`, `SpriteAdvance`); `$EE8C`-`$F010` (`Trail5+8`) |
| Writes | `$60B5`-`$620D` (system); `$7CB6`-`$803D` (`Trail1ListA+2`, `Trail2ListA`, `Trail3ListA`, `Trail4ListA` and 4 more); `$80E7` (`SpriteNum`); `$8121` (`ItemFlags`); `$82F8`-`$82FD` (`ModeVector`, `AttrModeVector`, `SpriteCall`); `$EE8D`-`$EF73` (`Trail5+9`) |

### `BigPrint` (`$78E3`)

**Draw mode 8: a sprite scaled by BigScaleX / BigScaleY, ORed or cleared**

Witness: L1 823 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 37 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 150,018 t-states own (0.01 %) |
| Runs (the other recordings) | 786 runs of its first instruction, entered by a jump (`stage1/rec/warp` 327, `stage1/rec/kb` 87, `stage1/rec/trails` 75 and 7 more) |
| Called from | `SpriteHeader` |
| Calls | `BigByte`, `JpMultiply`, `JpBufferAddr` |
| Reads | `$6958`-`$6959` (`BigScaleX`, `BigScaleY`); `$80DB`-`$80F6` (`SpriteX`, `SpriteY`, `ScreenBase`, `DestAddr` and 7 more) |
| Writes | `$695E` (`BigMask`); `$80DB`-`$80F6` (`SpriteX`, `SpriteY`, `ScreenBase`, `DestAddr` and 7 more) |

### `BigByte` (`$7946`)

**One sprite byte, scaled**

Witness: L1 10924 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 492 calls, 948,386 t-states own (0.06 %) |
| Runs (the other recordings) | 10,432 calls (`stage1/rec/warp` 4,338, `stage1/rec/kb` 1,150, `stage1/rec/trails` 996 and 7 more) |
| Called from | `BigPrint` |
| Calls | `BigPlot` |
| Reads | `$6958`-`$695E` (`BigScaleX`, `BigScaleY`, `BigRepeat`, `BigClear` and 2 more); `$9DD1`-`$9F3C` (`GameGfx+3701`); `$9F51`-`$9F5C` (`GameGfx+4085`); `$BA3C`-`$BA47` (`GameGfx+10976`); `$CA21`-`$CADC` (`GameGfx+15045`); `$CB85`-`$CBC8` (`GameGfx+15401`); 1 more ranges |
| Writes | `$695E` (`BigMask`) |

### `BigPlot` (`$7972`)

**One scaled pixel: OR the mask in or clear it**

Witness: L1 75443 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 3,332 calls, 378,508 t-states own (0.02 %) |
| Runs (the other recordings) | 72,111 calls (`stage1/rec/warp` 30,567, `stage1/rec/kb` 7,796, `stage1/rec/trails` 6,878 and 7 more) |
| Called from | `BigByte` |
| Reads | `$695B`-`$695E` (`BigClear`, `CursorPos`, `BigMask`); `$F052`-`$F529` (`BufferP1+22`, `BufferP1Zeros`, `Trail6Image`, `BufferP1Byte` and 1 more); `$F53C`-`$F578` (`BufferP1Rest+129`) |
| Writes | `$F052`-`$F529` (`BufferP1+22`, `BufferP1Zeros`, `Trail6Image`, `BufferP1Byte` and 1 more); `$F53C`-`$F578` (`BufferP1Rest+129`) |

### `CopyTrailName` (`$798C`)

**Copy the trail's 11-character name over the dots after "TRAIL NO." (TrailNameSlot)**

Witness: L1 21 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 1 call, 358 t-states own (0.00 %) |
| Runs (the other recordings) | 20 calls (`stage1/rec/warp` 8, `stage1/rec/kb` 2, `stage1/rec/trails` 2 and 7 more) |
| Called from | `TrailIntro` |
| Reads | `$79DA`-`$79E5` (`TrailNamePtrs`); `$79FC`-`$7A3D` (`TrailNameSlot+12`); `$D6BF`-`$D6C0` (`Trail`, `FinishDistance`) |
| Writes | `$79F0`-`$79FA` (`TrailNameSlot`) |

### `TrailAttrs` (`$79A9`)

**Colour a half's playfield with the trail's attribute (TrailInks): 22 x 5 cells at IX; trails 3 and 6 (Icebergs, Swamp) add a blue row (9) at IY**

Witness: L1 44 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 2 calls, 326 t-states own (0.00 %) |
| Runs (the other recordings) | 42 calls (`stage1/rec/warp` 16, `stage1/rec/kb` 6, `stage1/rec/trails` 4 and 7 more) |
| Called from | `TrailIntro` (tail), `PanelP2` (tail), `PanelP1` (tail) |
| Calls | `FillAttrs` |
| Reads | `$79D4`-`$79D9` (`TrailInks`); `$D6BF`-`$D6C0` (`Trail`, `FinishDistance`) |

### `P1UsesJoystick` (`$83F9`)

**Carry: player 1 reads the Kempston; else NZ: the Sinclair keys (two players and Keyboard1Alt)**

Witness: L1 136575 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 14,590 calls, 510,650 t-states own (0.03 %) |
| Runs (the other recordings) | 121,985 calls (`stage1/rec/warp` 44,410, `stage1/rec/trail1` 26,610, `stage1/rec/kb` 15,475 and 8 more) |
| Called from | `P1Left`, `P1Right`, `P1Up`, `P1Down`, `P1Jump` |
| Reads | `$6947` (`PlayerVars`); `$8086`-`$8087` (`KempstonOn`, `Keyboard1Alt`) |

### `P1Left` (`$840C`)

**Carry when player 1's left is held (the key KeyIndexes1+0, Kempston bit 1)**

Witness: L1 27315 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 2,918 calls, 198,424 t-states own (0.01 %) |
| Runs (the other recordings) | 24,397 calls (`stage1/rec/warp` 8,882, `stage1/rec/trail1` 5,322, `stage1/rec/kb` 3,095 and 8 more) |
| Called from | `JpP1Left` (tail) |
| Calls | `P1UsesJoystick` |
| Reads | `$8089`-`$8095` (`JoyBits`, `FillByte`, `KeyStates`); `$8109` (`KeyIndexes1`) |

### `P1Right` (`$842D`)

**Player 1's right (KeyIndexes1+1, Kempston bit 0)**

Witness: L1 27315 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 2,918 calls, 198,424 t-states own (0.01 %) |
| Runs (the other recordings) | 24,397 calls (`stage1/rec/warp` 8,882, `stage1/rec/trail1` 5,322, `stage1/rec/kb` 3,095 and 8 more) |
| Called from | `JpP1Right` (tail) |
| Calls | `P1UsesJoystick` |
| Reads | `$8089`-`$8092` (`JoyBits`, `FillByte`, `KeyStates`); `$810A` (`KeyIndexes1+1`) |

### `P1Up` (`$844E`)

**Player 1's wheel up (KeyIndexes1+2, Kempston bit 3)**

Witness: L1 27315 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 2,918 calls, 198,424 t-states own (0.01 %) |
| Runs (the other recordings) | 24,397 calls (`stage1/rec/warp` 8,882, `stage1/rec/trail1` 5,322, `stage1/rec/kb` 3,095 and 8 more) |
| Called from | `JpP1Up` (tail) |
| Calls | `P1UsesJoystick` |
| Reads | `$8089`-`$8093` (`JoyBits`, `FillByte`, `KeyStates`); `$80A5` (`KeyStates+26`); `$810B` (`KeyIndexes1+2`) |

### `P1Down` (`$846F`)

**Player 1's wheel down (KeyIndexes1+3, Kempston bit 2)**

Witness: L1 27315 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 2,918 calls, 198,424 t-states own (0.01 %) |
| Runs (the other recordings) | 24,397 calls (`stage1/rec/warp` 8,882, `stage1/rec/trail1` 5,322, `stage1/rec/kb` 3,095 and 8 more) |
| Called from | `JpP1Down` (tail) |
| Calls | `P1UsesJoystick` |
| Reads | `$8089`-`$808E` (`JoyBits`, `FillByte`, `KeyStates`); `$80A4` (`KeyStates+25`); `$810C` (`KeyIndexes1+3`) |

### `P1Jump` (`$8490`)

**Player 1's jump (KeyIndexes1+4, Kempston fire, bit 4)**

Witness: L1 27315 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 2,918 calls, 198,424 t-states own (0.01 %) |
| Runs (the other recordings) | 24,397 calls (`stage1/rec/warp` 8,882, `stage1/rec/trail1` 5,322, `stage1/rec/kb` 3,095 and 8 more) |
| Called from | `JpP1Jump` (tail) |
| Calls | `P1UsesJoystick` |
| Reads | `$8089`-`$808C` (`JoyBits`, `FillByte`, `KeyStates`); `$80B0` (`KeyStates+37`); `$810D` (`KeyIndexes1+4`) |

### `P2Left` (`$84B1`)

**Player 2's left: KeyIndexes2+0, or key 6 with the Sinclair joystick**

Witness: L1 27315 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 2,918 calls, 186,752 t-states own (0.01 %) |
| Runs (the other recordings) | 24,397 calls (`stage1/rec/warp` 8,882, `stage1/rec/trail1` 5,322, `stage1/rec/kb` 3,095 and 8 more) |
| Called from | `JpP2Left` (tail) |
| Reads | `$8088` (`SinclairOn`); `$80A3`-`$80AD` (`KeyStates+24`); `$810E` (`KeyIndexes2`) |

### `P2Right` (`$84CF`)

**Player 2's right: KeyIndexes2+1 or key 7**

Witness: L1 27315 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 2,918 calls, 186,752 t-states own (0.01 %) |
| Runs (the other recordings) | 24,397 calls (`stage1/rec/warp` 8,882, `stage1/rec/trail1` 5,322, `stage1/rec/kb` 3,095 and 8 more) |
| Called from | `JpP2Right` (tail) |
| Reads | `$8088` (`SinclairOn`); `$80A2`-`$80AC` (`KeyStates+23`); `$810F` (`KeyIndexes2+1`) |

### `P2Up` (`$84ED`)

**Player 2's wheel up: KeyIndexes2+2 or key 9**

Witness: L1 27315 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 2,918 calls, 186,752 t-states own (0.01 %) |
| Runs (the other recordings) | 24,397 calls (`stage1/rec/warp` 8,882, `stage1/rec/trail1` 5,322, `stage1/rec/kb` 3,095 and 8 more) |
| Called from | `JpP2Up` (tail) |
| Reads | `$8088` (`SinclairOn`); `$80A0`-`$80AB` (`KeyStates+21`); `$8110` (`KeyIndexes2+2`) |

### `P2Down` (`$850B`)

**Player 2's wheel down: KeyIndexes2+3 or key 8**

Witness: L1 27315 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 2,918 calls, 186,752 t-states own (0.01 %) |
| Runs (the other recordings) | 24,397 calls (`stage1/rec/warp` 8,882, `stage1/rec/trail1` 5,322, `stage1/rec/kb` 3,095 and 8 more) |
| Called from | `JpP2Down` (tail) |
| Reads | `$8088` (`SinclairOn`); `$80A1`-`$80B0` (`KeyStates+22`); `$8111` (`KeyIndexes2+3`) |

### `P2Jump` (`$8529`)

**Player 2's jump: KeyIndexes2+4 or key 0**

Witness: L1 27315 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 2,918 calls, 186,752 t-states own (0.01 %) |
| Runs (the other recordings) | 24,397 calls (`stage1/rec/warp` 8,882, `stage1/rec/trail1` 5,322, `stage1/rec/kb` 3,095 and 8 more) |
| Called from | `JpP2Jump` (tail) |
| Reads | `$8088` (`SinclairOn`); `$809F` (`KeyStates+20`); `$80B2` (`KeyStates+39`); `$8112` (`KeyIndexes2+4`) |

### `ClearKeys` (`$858A`)

**Zero KeyStates and JoyBits**

Witness: L1 418942 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 17,303 calls, 15,247,933 t-states own (0.97 %) |
| Runs (the other recordings) | 401,639 calls (`stage1/rec/warp` 239,417, `stage1/rec/kb` 100,054, `stage1/rec/trail1` 56,076 and 8 more) |
| Called from | `JpClearKeys` (tail) |
| Reads | `$808B`-`$80B1` (`KeyStates`) |
| Writes | `$8089`-`$80B2` (`JoyBits`, `FillByte`, `KeyStates`) |

### `ScanKeys` (`$859C`)

**Read the eight half-rows into KeyStates (1 a key held) and OR the Kempston's bits into JoyBits**

Ports `$FEFE` to `$7FFE`, five bits each; then IN 31. Called each frame by the interrupt in the front end and each pass in play. L is loaded but not used. The latch keeps a key for 3 scans: only the last 3 interrupts of a 7-frame pass count.

Witness: L1 143606 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

[Animation: `ScanKeys` at work](img/routines/ScanKeys.gif)

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 23,340 calls, 47,747,315 t-states own (3.05 %) |
| Runs (the other recordings) | 120,266 calls (`stage1/rec/trail1` 64,164, `stage1/rec/warp` 16,548, `stage1/rec/fuel` 9,295 and 8 more) |
| Called from | `JpScanKeys` (tail) |
| Reads | `$8089` (`JoyBits`) |
| Writes | `$8089`-`$80B2` (`JoyBits`, `FillByte`, `KeyStates`); `$D726`-`$D727` (`RecordP1+24`); `$D78A`-`$D78B` (`TrackPos`) |
| Ports in | `$001F`, `$7FFE`, `$BFFE`, `$DFFE`, `$EFFE`, `$F7FE`, `$FBFE`, `$FDFE`, `$FEFE` |

## render

`src/game/render.asm`

### `GfxTable` (`$82FE`)

**The renderer's jump table; the first entry JP ScreenAddr**

The entries at `$8307`, `$830A`, `$834F`, `$835E`, `$8361` and `$8367` are called by no one (known only from the code).

Witness: L1 4078 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 143 calls, 1,430 t-states own (0.00 %) |
| Runs (the other recordings) | 3,935 calls (`stage1/rec/trails` 1,094, `stage1/rec/warp` 740, `stage1/rec/kb` 692 and 8 more) |
| Called from | `Checker`, `MenuBoxScreen`, `ScreenAddrHL` (tail), `FuelBarStep`, `SpeedBar`, `BarNibble`, `ShowBars` |
| Calls | `ScreenAddr` (tail) |

### `JpNextLineHL` (`$8301`)

**JP NextLineHL**

Witness: L1 38397 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 3,159 calls, 31,609 t-states own (0.00 %) |
| Runs (the other recordings) | 35,238 calls (`stage1/rec/warp` 6,439, `stage1/rec/kb` 4,071, `stage1/rec/trails` 3,463 and 7 more) |
| Called from | `FillColumn`, `PanelP1`, `CheckerColumn`, `FillEveryOther`, `ClearBottomHalf`, `BuildRowAddrs`, `ScaleRight` |
| Calls | `NextLineHL` (tail) |

### `JpNextLineDE` (`$8304`)

**JP NextLineDE**

Witness: L1 72342 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 9,920 calls, 99,238 t-states own (0.01 %) |
| Runs (the other recordings) | 62,422 calls (`stage1/rec/warp` 15,244, `stage1/rec/fuel` 9,606, `stage1/rec/trails` 9,394 and 8 more) |
| Called from | `Dissolve`, `Scroller`, `ModeCopyScreen` |
| Calls | `NextLineDE` (tail) |

### `JpPrevLineHL` (`$8307`)

**JP PrevLineHL**

Known only from the code: no recording runs it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `JpPrevLineDE` (`$830A`)

**JP PrevLineDE**

Known only from the code: no recording runs it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `JpClearKeys` (`$830D`)

**JP ClearKeys**

Witness: L1 418942 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 17,303 calls, 173,030 t-states own (0.01 %) |
| Runs (the other recordings) | 401,639 calls (`stage1/rec/warp` 239,417, `stage1/rec/kb` 100,054, `stage1/rec/trail1` 56,076 and 8 more) |
| Called from | `WaitKey60`, `WaitNoKey`, `MenuLoop`, `ReadNewKey`, `ReadControlRaw`, `NewGame`, `Init`, `PassP1` |
| Calls | `ClearKeys` (tail) |

### `JpScanKeys` (`$8310`)

**JP ScanKeys**

Witness: L1 143606 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 23,340 calls, 233,400 t-states own (0.01 %) |
| Runs (the other recordings) | 120,266 calls (`stage1/rec/trail1` 64,164, `stage1/rec/warp` 16,548, `stage1/rec/fuel` 9,295 and 8 more) |
| Called from | `AnyKey`, `Interrupt` |
| Calls | `ScanKeys` (tail) |

### `JpGameSpriteAt` (`$8313`)

**JP GameSpriteAt**

Witness: L1 16821 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 727 calls, 7,270 t-states own (0.00 %) |
| Runs (the other recordings) | 16,094 calls (`stage1/rec/warp` 8,490, `stage1/rec/kb` 2,384, `stage1/rec/trails` 1,800 and 7 more) |
| Called from | `SpriteList`, `BigDigit`, `ScoreDigit` |
| Calls | `GameSpriteAt` (tail) |

### `JpGameSprite` (`$8316`)

**JP GameSprite**

Witness: L1 63645 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 3,285 calls, 33,120 t-states own (0.00 %) |
| Runs (the other recordings) | 59,658 calls (`stage1/rec/trails` 23,035, `stage1/rec/kb` 10,459, `stage1/rec/warp` 10,040 and 8 more) |
| Called from | `PutGameSprite` (tail), `HiScoreScreen`, `Print`, `SpriteGo`, `DrawAtv`, `Wheels`, `DrawRider` |
| Calls | `GameSprite` (tail) |

### `JpMenuSpriteAt` (`$8319`)

**JP MenuSpriteAt**

Witness: L1 77 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 7 calls, 70 t-states own (0.00 %) |
| Runs (the other recordings) | 70 calls (`stage1/rec/empty` 7, `stage1/rec/fuel` 7, `stage1/rec/kb` 7 and 7 more) |
| Called from | `SpriteList` |
| Calls | `MenuSpriteAt` (tail) |

### `JpMenuSprite` (`$831C`)

**JP MenuSprite**

Witness: L1 61 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 2 calls, 40 t-states own (0.00 %) |
| Runs (the other recordings) | 4 calls (`stage1/rec/menu` 2, `stage1/rec/warp` 1, `stage1/rec/trail1` 1) |
| Called from | `PutMenuSprite` (tail), `SpriteGo` |
| Calls | `MenuSprite` (tail) |

### `JpMultiply` (`$831F`)

**JP Multiply**

Witness: L1 1099 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 56 calls, 560 t-states own (0.00 %) |
| Runs (the other recordings) | 1,043 calls (`stage1/rec/warp` 423, `stage1/rec/kb` 152, `stage1/rec/wallcrash` 97 and 8 more) |
| Called from | `Highlight`, `KeySlot`, `BigPrint`, `NameEntry`, `ReadControlRaw`, `Update`, `DigitsValue`, `ClipTop`, `SelectTrail` |
| Calls | `Multiply` (tail) |

### `JpP1Left` (`$8322`)

**JP P1Left**

Witness: L1 27315 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 2,918 calls, 29,180 t-states own (0.00 %) |
| Runs (the other recordings) | 24,397 calls (`stage1/rec/warp` 8,882, `stage1/rec/trail1` 5,322, `stage1/rec/kb` 3,095 and 8 more) |
| Called from | `ReadP1Controls` |
| Calls | `P1Left` (tail) |

### `JpP1Right` (`$8325`)

**JP P1Right**

Witness: L1 27315 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 2,918 calls, 29,180 t-states own (0.00 %) |
| Runs (the other recordings) | 24,397 calls (`stage1/rec/warp` 8,882, `stage1/rec/trail1` 5,322, `stage1/rec/kb` 3,095 and 8 more) |
| Called from | `ReadP1Controls` |
| Calls | `P1Right` (tail) |

### `JpP1Up` (`$8328`)

**JP P1Up**

Witness: L1 27315 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 2,918 calls, 29,180 t-states own (0.00 %) |
| Runs (the other recordings) | 24,397 calls (`stage1/rec/warp` 8,882, `stage1/rec/trail1` 5,322, `stage1/rec/kb` 3,095 and 8 more) |
| Called from | `ReadP1Controls` |
| Calls | `P1Up` (tail) |

### `JpP1Down` (`$832B`)

**JP P1Down**

Witness: L1 27315 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 2,918 calls, 29,180 t-states own (0.00 %) |
| Runs (the other recordings) | 24,397 calls (`stage1/rec/warp` 8,882, `stage1/rec/trail1` 5,322, `stage1/rec/kb` 3,095 and 8 more) |
| Called from | `ReadP1Controls` |
| Calls | `P1Down` (tail) |

### `JpP1Jump` (`$832E`)

**JP P1Jump**

Witness: L1 27315 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 2,918 calls, 29,180 t-states own (0.00 %) |
| Runs (the other recordings) | 24,397 calls (`stage1/rec/warp` 8,882, `stage1/rec/trail1` 5,322, `stage1/rec/kb` 3,095 and 8 more) |
| Called from | `ReadP1Controls` |
| Calls | `P1Jump` (tail) |

### `JpP2Left` (`$8331`)

**JP P2Left**

Witness: L1 27315 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 2,918 calls, 29,180 t-states own (0.00 %) |
| Runs (the other recordings) | 24,397 calls (`stage1/rec/warp` 8,882, `stage1/rec/trail1` 5,322, `stage1/rec/kb` 3,095 and 8 more) |
| Called from | `ReadP2Controls` |
| Calls | `P2Left` (tail) |

### `JpP2Right` (`$8334`)

**JP P2Right**

Witness: L1 27315 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 2,918 calls, 29,180 t-states own (0.00 %) |
| Runs (the other recordings) | 24,397 calls (`stage1/rec/warp` 8,882, `stage1/rec/trail1` 5,322, `stage1/rec/kb` 3,095 and 8 more) |
| Called from | `ReadP2Controls` |
| Calls | `P2Right` (tail) |

### `JpP2Up` (`$8337`)

**JP P2Up**

Witness: L1 27315 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 2,918 calls, 29,180 t-states own (0.00 %) |
| Runs (the other recordings) | 24,397 calls (`stage1/rec/warp` 8,882, `stage1/rec/trail1` 5,322, `stage1/rec/kb` 3,095 and 8 more) |
| Called from | `ReadP2Controls` |
| Calls | `P2Up` (tail) |

### `JpP2Down` (`$833A`)

**JP P2Down**

Witness: L1 27315 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 2,918 calls, 29,180 t-states own (0.00 %) |
| Runs (the other recordings) | 24,397 calls (`stage1/rec/warp` 8,882, `stage1/rec/trail1` 5,322, `stage1/rec/kb` 3,095 and 8 more) |
| Called from | `ReadP2Controls` |
| Calls | `P2Down` (tail) |

### `JpP2Jump` (`$833D`)

**JP P2Jump**

Witness: L1 27315 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 2,918 calls, 29,180 t-states own (0.00 %) |
| Runs (the other recordings) | 24,397 calls (`stage1/rec/warp` 8,882, `stage1/rec/trail1` 5,322, `stage1/rec/kb` 3,095 and 8 more) |
| Called from | `ReadP2Controls` |
| Calls | `P2Jump` (tail) |

### `JpCopyBufferP1` (`$8340`)

**JP CopyBufferP1**

Witness: L1 5870 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 601 calls, 6,010 t-states own (0.00 %) |
| Runs (the other recordings) | 5,269 calls (`stage1/rec/fuel` 1,254, `stage1/rec/trails` 920, `stage1/rec/warp` 894 and 7 more) |
| Called from | `PassP1`, `TimeOut` |
| Calls | `CopyBufferP1` (tail) |

### `JpCopyBufferP2` (`$8343`)

**JP CopyBufferP2**

Witness: L1 814 (kb).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 814 calls (`stage1/rec/kb` 814) |
| Called from | `PassP2`, `TimeOut` (tail) |
| Calls | `CopyBufferP2` (tail) |

### `JpCopyLines` (`$8346`)

**JP CopyLines**

Witness: L1 188 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 67 calls, 670 t-states own (0.00 %) |
| Runs (the other recordings) | 121 calls (`stage1/rec/warp` 46, `stage1/rec/trail1` 34, `stage1/rec/menu` 25 and 8 more) |
| Called from | `ShowBufferAt` (tail) |
| Calls | `CopyLines` (tail) |

### `JpClearBufferP1` (`$8349`)

**JP ClearBufferP1**

Witness: L1 5968 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 612 calls, 6,120 t-states own (0.00 %) |
| Runs (the other recordings) | 5,356 calls (`stage1/rec/fuel` 1,256, `stage1/rec/trails` 925, `stage1/rec/warp` 919 and 8 more) |
| Called from | `TrailIntro`, `Credits`, `HiScoreScreen`, `TrailListScreen`, `MenuBoxDraw`, `NameEntry`, `NameScreen`, `PassP1` |
| Calls | `ClearBufferP1` (tail) |

### `JpClearBufferP2` (`$834C`)

**JP ClearBufferP2**

Witness: L1 813 (kb).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 813 calls (`stage1/rec/kb` 813) |
| Called from | `PassP2` |
| Calls | `ClearBufferP2` (tail) |

### `JpAttrAddrPlay` (`$834F`)

**JP AttrAddrPlay**

Known only from the code: no recording runs it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `JpBufferAddr` (`$8352`)

**JP BufferAddr**

Witness: L1 77151 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 4,524 calls, 45,240 t-states own (0.00 %) |
| Runs (the other recordings) | 72,627 calls (`stage1/rec/trails` 24,954, `stage1/rec/kb` 13,799, `stage1/rec/warp` 12,155 and 8 more) |
| Called from | `PutMenuSprite`, `PutGameSprite`, `FrameBox`, `HiScoreScreen`, `Print`, `BigPrint`, `ClipY`, `AtvPhysics`, `GroundUnder`, `RiderGround` |
| Calls | `BufferAddr` (tail) |

### `JpFlushAttrs` (`$8355`)

**JP FlushAttrs**

Witness: L1 6679 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 600 calls, 6,000 t-states own (0.00 %) |
| Runs (the other recordings) | 6,079 calls (`stage1/rec/kb` 1,626, `stage1/rec/fuel` 1,254, `stage1/rec/trails` 920 and 7 more) |
| Called from | `PassP1`, `PassP2` |
| Calls | `FlushAttrs` (tail) |

### `JpFlushDeferredA` (`$8358`)

**JP FlushDeferredA**

Witness: L1 6679 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 600 calls, 6,000 t-states own (0.00 %) |
| Runs (the other recordings) | 6,079 calls (`stage1/rec/kb` 1,626, `stage1/rec/fuel` 1,254, `stage1/rec/trails` 920 and 7 more) |
| Called from | `Update` |
| Calls | `FlushDeferredA` (tail) |

### `JpFlushDeferredB` (`$835B`)

**JP FlushDeferredB**

Witness: L1 6679 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 600 calls, 6,000 t-states own (0.00 %) |
| Runs (the other recordings) | 6,079 calls (`stage1/rec/kb` 1,626, `stage1/rec/fuel` 1,254, `stage1/rec/trails` 920 and 7 more) |
| Called from | `Update` |
| Calls | `FlushDeferredB` (tail) |

### `JpDeferA` (`$835E`)

**JP DeferA**

Known only from the code: no recording runs it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `JpDeferB` (`$8361`)

**JP DeferB**

Known only from the code: no recording runs it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `JpWalkList` (`$8364`)

**JP WalkList**

Witness: L1 13361 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 1,200 calls, 12,000 t-states own (0.00 %) |
| Runs (the other recordings) | 12,161 calls (`stage1/rec/kb` 3,252, `stage1/rec/fuel` 2,508, `stage1/rec/trails` 1,842 and 7 more) |
| Called from | `Update` |
| Calls | `WalkList` (tail) |

### `JpPlaceClipped` (`$8367`)

**JP PlaceClipped**

Known only from the code: no recording runs it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `JpSpriteGo` (`$836A`)

**JP SpriteGo**

Witness: L1 757 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 29 calls, 290 t-states own (0.00 %) |
| Runs (the other recordings) | 728 calls (`stage1/rec/warp` 323, `stage1/rec/kb` 77, `stage1/rec/trails` 77 and 7 more) |
| Called from | `InitList` |
| Calls | `SpriteGo` (tail) |

### `MaskFromLeft` (`$8379`)

**A = SpriteX AND 7 XOR 7 + 1 bits set from the left (no caller)**

Known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `MaskFromRight` (`$838A`)

**A = SpriteX AND 7 + 1 bits set from the right (no caller)**

Known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ScreenAddr` (`$8399`)

**HL = the screen address of SpriteX / SpriteY (y up from the bottom, RowAddrs) + ScreenBase**

Witness: L1 20976 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 877 calls, 216,884 t-states own (0.01 %) |
| Runs (the other recordings) | 20,099 calls (`stage1/rec/warp` 9,237, `stage1/rec/kb` 3,083, `stage1/rec/trails` 2,901 and 8 more) |
| Called from | `GfxTable` (tail), `GameSpriteAt`, `MenuSpriteAt` |
| Reads | `$6727`-`$6748` (`RowAddrs`); `$675B`-`$6798` (`RowAddrs+52`); `$67D1`-`$6808` (`RowAddrs+170`); `$6827`-`$6830` (`RowAddrs+256`); `$6857`-`$6858` (`RowAddrs+304`); `$6899`-`$689C` (`RowAddrs+370`); 1 more ranges |

### `Multiply` (`$83E5`)

**HL = A x E (8 x 8 bits)**

Witness: L1 78259 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 3,980 calls, 1,673,575 t-states own (0.11 %) |
| Runs (the other recordings) | 74,279 calls (`stage1/rec/trails` 17,784, `stage1/rec/kb` 16,177, `stage1/rec/warp` 14,783 and 8 more) |
| Called from | `JpMultiply` (tail), `ShiftBytesRight`, `RotateSpriteLeft` |

### `CopyBlockUnused` (`$8547`)

**Copy a sprite's lines into the buffer (no caller)**

Known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `XorBlockUnused` (`$8567`)

**XOR a sprite into the buffer, another copy of ModeXorBuffer (no caller)**

Known only from the code: no recording runs it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `NextLineHL` (`$85D0`)

**HL one screen line down**

Witness: L1 38397 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 3,159 calls, 96,660 t-states own (0.01 %) |
| Runs (the other recordings) | 35,238 calls (`stage1/rec/warp` 6,439, `stage1/rec/kb` 4,071, `stage1/rec/trails` 3,463 and 7 more) |
| Called from | `JpNextLineHL` (tail) |

### `NextLineDE` (`$85DF`)

**DE one screen line down**

Witness: L1 622102 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 63,360 calls, 1,942,733 t-states own (0.12 %) |
| Runs (the other recordings) | 558,742 calls (`stage1/rec/kb` 139,146, `stage1/rec/fuel` 110,006, `stage1/rec/warp` 90,444 and 8 more) |
| Called from | `JpNextLineDE` (tail), `CopyLines` |

### `PrevLineHL` (`$85EE`)

**HL one screen line up (no caller)**

Known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PrevLineDE` (`$85FF`)

**DE one screen line up (no caller)**

Known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `GameSpriteAt` (`$8610`)

**DestAddr = the screen address; GameSprite**

Witness: L1 16821 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 727 calls, 23,991 t-states own (0.00 %) |
| Runs (the other recordings) | 16,094 calls (`stage1/rec/warp` 8,490, `stage1/rec/kb` 2,384, `stage1/rec/trails` 1,800 and 7 more) |
| Called from | `JpGameSpriteAt` (tail) |
| Calls | `ScreenAddr`, `GameSprite` (falls into) |
| Writes | `$80E5`-`$80E6` (`DestAddr`) |

### `GameSprite` (`$8616`)

**Draw in-game sprite SpriteNum (GameGfx): the header, the shift, the draw mode**

No sprite past the bank's count. HL = `$8F5C` + the word at `$8F60` + 2 x SpriteNum: SpriteHeader.

Witness: L1 194316 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 4,039 calls, 1,579,409 t-states own (0.10 %) |
| Runs (the other recordings) | 76,427 calls (`stage1/rec/trails` 24,908, `stage1/rec/warp` 18,824, `stage1/rec/kb` 12,916 and 8 more) |
| Called from | `JpGameSprite` (tail), `GameSpriteAt` (falls into), `SpriteGo` |
| Calls | `SpriteHeader` (tail) |
| Reads | `$80E7` (`SpriteNum`); `$8F5C`-`$90F5` (`GameGfx`) |

### `MenuSpriteAt` (`$8637`)

**DestAddr = the screen address; MenuSprite**

Witness: L1 77 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 7 calls, 231 t-states own (0.00 %) |
| Runs (the other recordings) | 70 calls (`stage1/rec/empty` 7, `stage1/rec/fuel` 7, `stage1/rec/kb` 7 and 7 more) |
| Called from | `JpMenuSpriteAt` (tail) |
| Calls | `ScreenAddr`, `MenuSprite` (falls into) |
| Writes | `$80E5`-`$80E6` (`DestAddr`) |

### `MenuSprite` (`$863D`)

**Draw front-end picture SpriteNum (MenuGfx)**

Witness: L1 4685 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 11 calls, 19,829 t-states own (0.00 %) |
| Runs (the other recordings) | 127 calls (`stage1/rec/warp` 37, `stage1/rec/trails` 11, `stage1/rec/kb` 11 and 8 more) |
| Called from | `JpMenuSprite` (tail), `MenuSpriteAt` (falls into), `SpriteGo` |
| Calls | `SpriteHeader` (falls into) |
| Reads | `$6338`-`$6371` (`MenuGfx`); `$80E7` (`SpriteNum`) |

### `SpriteHeader` (`$865F`)

**Read a sprite's header (width, height, advance, shift) and shift it to SpriteX's bit offset; call the draw mode**

HL the header. +0 SpriteWidth, +1 SpriteHeight, +2 Advance, +3 the shift now in the bytes (ShiftPtr), +4 the bytes. When SpriteX AND 7 differs from the shift, ShiftLeftBy / ShiftRightBy move the bytes right or left the short way (up to 4 bits) and stores the new shift: the bank is shifted in place, on demand, and stays so. Then JP (the word at ModeVector).

Witness: L1 199001 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 10,310 calls, 2,924,202 t-states own (0.19 %) |
| Runs (the other recordings) | 188,691 calls (`stage1/rec/kb` 45,803, `stage1/rec/trails` 39,662, `stage1/rec/warp` 37,515 and 8 more) |
| Called from | `GameSprite` (tail), `MenuSprite` (falls into) |
| Calls | `ModeNone`, `ModeCopyScreen`, `ModeXorScreen`, `ModeCopyBuffer`, `ModeXorBuffer`, `BigPrint`, `ShiftLeftBy`, `ShiftRightBy`, `MaskBufferAlt`, `MaskBufferClip`, `OrBuffer`, `OrBufferClip` |
| Reads | `$6374`-`$66EA` (`MenuGfx+60`); `$69F7`-`$6A08` (`DrawModes`); `$80DB` (`SpriteX`); `$80F2`-`$80F5` (`SpriteWidth`, `SpriteHeight`, `ShiftPtr`); `$82F8`-`$82F9` (`ModeVector`); `$836D`-`$8378` (`ListModes`); 2 more ranges |
| Writes | `$80E8`-`$80F6` (`SpriteData`, `MaskData`, `SpriteWidth`, `SpriteHeight` and 2 more) |

### `ShiftBytesRight` (`$86C4`)

**Move every line's bytes one byte right (the last byte dropped, a zero in)**

Witness: L1 10429 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 208 calls, 537,961 t-states own (0.03 %) |
| Runs (the other recordings) | 10,221 calls (`stage1/rec/trails` 2,892, `stage1/rec/kb` 1,878, `stage1/rec/warp` 1,447 and 8 more) |
| Called from | `ShiftLeftBy` |
| Calls | `Multiply` |
| Reads | `$650C`-`$66F1` (`MenuGfx+468`); `$80E8`-`$80FF` (`SpriteData`, `MaskData`, `SpriteWidth`, `SpriteHeight` and 7 more); `$90FA`-`$9F4B` (`GameGfx+414`); `$AC90`-`$C045` (`GameGfx+7476`); `$CB85`-`$D678` (`GameGfx+15401`) |
| Writes | `$650C`-`$66F2` (`MenuGfx+468`); `$80FF` (`LineCount`); `$90FA`-`$9F4C` (`GameGfx+414`); `$AC90`-`$C046` (`GameGfx+7476`); `$CB85`-`$D679` (`GameGfx+15401`); `$D726`-`$D727` (`RecordP1+24`); 1 more ranges |

### `ShiftBytesLeft` (`$86F7`)

**Move every line's bytes one byte left**

Witness: L1 9965 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 152 calls, 452,877 t-states own (0.03 %) |
| Runs (the other recordings) | 9,813 calls (`stage1/rec/trails` 2,314, `stage1/rec/fuel` 2,252, `stage1/rec/kb` 1,687 and 8 more) |
| Called from | `ShiftRightBy` |
| Reads | `$650D`-`$66F2` (`MenuGfx+469`); `$80E8`-`$80FF` (`SpriteData`, `MaskData`, `SpriteWidth`, `SpriteHeight` and 7 more); `$90FB`-`$9F5C` (`GameGfx+415`); `$ACB6`-`$AD88` (`GameGfx+7514`); `$B260`-`$C046` (`GameGfx+8964`); `$CB98`-`$D679` (`GameGfx+15420`) |
| Writes | `$650C`-`$66F2` (`MenuGfx+468`); `$80FF` (`LineCount`); `$90FA`-`$9F5C` (`GameGfx+414`); `$ACB5`-`$AD88` (`GameGfx+7513`); `$B25F`-`$C046` (`GameGfx+8963`); `$CB97`-`$D679` (`GameGfx+15419`) |

### `RotateSpriteLeft` (`$871E`)

**Shift the sprite's bytes one bit left (the whole width)**

Witness: L1 66731 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

[Animation: `RotateSpriteLeft` at work](img/routines/RotateSpriteLeft.gif)

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 3,716 calls, 10,179,209 t-states own (0.65 %) |
| Runs (the other recordings) | 63,015 calls (`stage1/rec/trails` 14,809, `stage1/rec/kb` 14,147, `stage1/rec/warp` 12,913 and 8 more) |
| Called from | `ShiftLeftBy` |
| Calls | `Multiply` |
| Reads | `$650C`-`$66F2` (`MenuGfx+468`); `$80E8`-`$80F3` (`SpriteData`, `MaskData`, `SpriteWidth`, `SpriteHeight`); `$90FA`-`$9F5C` (`GameGfx+414`); `$AC90`-`$C186` (`GameGfx+7476`); `$CA01`-`$D679` (`GameGfx+15013`) |
| Writes | `$650C`-`$66F2` (`MenuGfx+468`); `$90FA`-`$9F5C` (`GameGfx+414`); `$AC90`-`$C186` (`GameGfx+7476`); `$CA01`-`$D78B` (`GameGfx+15013`, `EntryJumps`, `LoopVars`, `GameTable` and 19 more) |

### `RotateSpriteRight` (`$8742`)

**Shift the sprite's bytes one bit right**

Witness: L1 65659 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 3,568 calls, 10,439,920 t-states own (0.67 %) |
| Runs (the other recordings) | 62,091 calls (`stage1/rec/fuel` 16,214, `stage1/rec/kb` 12,997, `stage1/rec/warp` 10,968 and 8 more) |
| Called from | `ShiftRightBy` |
| Reads | `$650C`-`$66F2` (`MenuGfx+468`); `$80E8`-`$80F3` (`SpriteData`, `MaskData`, `SpriteWidth`, `SpriteHeight`); `$90FA`-`$9F6C` (`GameGfx+414`); `$ACB5`-`$C186` (`GameGfx+7513`); `$C9C1`-`$D679` (`GameGfx+14949`) |
| Writes | `$650C`-`$66F2` (`MenuGfx+468`); `$90FA`-`$9F6C` (`GameGfx+414`); `$ACB5`-`$C186` (`GameGfx+7513`); `$C9C1`-`$D679` (`GameGfx+14949`) |

### `ShiftLeftBy` (`$8759`)

**Shift A bits left, a byte along when the shift wraps**

Witness: L1 33401 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 1,808 calls, 439,167 t-states own (0.03 %) |
| Runs (the other recordings) | 31,593 calls (`stage1/rec/trails` 8,423, `stage1/rec/kb` 7,393, `stage1/rec/warp` 6,630 and 8 more) |
| Called from | `SpriteHeader` |
| Calls | `ShiftBytesRight`, `RotateSpriteLeft` |
| Reads | `$650B`-`$66EA` (`MenuGfx+467`); `$80F4`-`$8100` (`ShiftPtr`, `SpriteAdvance`, `AttrDest`, `AttrSrc` and 4 more); `$90F9`-`$9F50` (`GameGfx+413`); `$AC8F`-`$BF2F` (`GameGfx+7475`); `$C04A`-`$C0EA` (`GameGfx+12526`); `$CA00`-`$D656` (`GameGfx+15012`) |
| Writes | `$650B`-`$66EA` (`MenuGfx+467`); `$8100` (`ShiftCount`); `$90F9`-`$9F50` (`GameGfx+413`); `$AC8F`-`$BF2F` (`GameGfx+7475`); `$C04A`-`$C0EA` (`GameGfx+12526`); `$CA00`-`$D656` (`GameGfx+15012`) |

### `ShiftRightBy` (`$8777`)

**Shift A bits right**

Witness: L1 31357 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 1,704 calls, 396,900 t-states own (0.03 %) |
| Runs (the other recordings) | 29,653 calls (`stage1/rec/kb` 7,196, `stage1/rec/fuel` 5,938, `stage1/rec/trails` 5,633 and 8 more) |
| Called from | `SpriteHeader` |
| Calls | `ShiftBytesLeft`, `RotateSpriteRight` |
| Reads | `$650B`-`$66EA` (`MenuGfx+467`); `$80F4`-`$8100` (`ShiftPtr`, `SpriteAdvance`, `AttrDest`, `AttrSrc` and 4 more); `$90F9`-`$9F60` (`GameGfx+413`); `$ACB4`-`$B05C` (`GameGfx+7512`); `$B25E`-`$BF2F` (`GameGfx+8962`); `$C04A`-`$C0EA` (`GameGfx+12526`); 1 more ranges |
| Writes | `$650B`-`$66EA` (`MenuGfx+467`); `$8100` (`ShiftCount`); `$90F9`-`$9F60` (`GameGfx+413`); `$ACB4`-`$B05C` (`GameGfx+7512`); `$B25E`-`$BF2F` (`GameGfx+8962`); `$C04A`-`$C0EA` (`GameGfx+12526`); 1 more ranges |

### `AttrAddrPlay` (`$8799`)

**HL = the attribute address of SpriteX / SpriteY in the play area (80 lines, AttrBase)**

Witness: L1 2139 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 54 calls, 10,152 t-states own (0.00 %) |
| Runs (the other recordings) | 2,085 calls (`stage1/rec/warp` 641, `stage1/rec/trails` 531, `stage1/rec/kb` 284 and 7 more) |
| Called from | `DeferAttrs` |
| Reads | `$8084`-`$8085` (`AttrBase`); `$80DB`-`$80DD` (`SpriteX`, `SpriteY`) |

### `BufferAddr` (`$87C4`)

**HL = the buffer address of SpriteX / SpriteY (BufferRows, BufferBase)**

LD E,`$00` (the clamp for y above `$4F`) is dead: E is overwritten at `$87D0`.

Witness: L1 120931 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 6,425 calls, 1,333,005 t-states own (0.09 %) |
| Runs (the other recordings) | 114,506 calls (`stage1/rec/trails` 30,411, `stage1/rec/kb` 26,845, `stage1/rec/fuel` 19,052 and 8 more) |
| Called from | `JpBufferAddr` (tail), `PlaceClipped` |
| Reads | `$68A7`-`$693C` (`BufferRows`); `$80DB`-`$80DD` (`SpriteX`, `SpriteY`); `$8144`-`$8145` (`BufferBase`) |

### `MaskBufferAlt` (`$87F1`)

**Masked draw: (buffer AND NOT mask) XOR sprite**

Witness: L1 769 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 23 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 645,881 t-states own (0.04 %) |
| Runs (the other recordings) | 746 runs of its first instruction, entered by a jump (`stage1/rec/warp` 235, `stage1/rec/kb` 166, `stage1/rec/empty` 109 and 7 more) |
| Called from | `SpriteHeader` |
| Reads | `$80E5`-`$80F3` (`DestAddr`, `SpriteNum`, `SpriteData`, `MaskData` and 2 more); `$BE15`-`$C046` (`GameGfx+11961`); `$CC73`-`$CE38` (`GameGfx+15639`); `$F33E`-`$F71B` (`Trail6Image+270`, `BufferP1Byte`, `BufferP1Rest`); `$FA1E`-`$FDFB` (`SetTransposeA+7`, `SetTransposeB`, `Drums`, `DrumPad` and 22 more) |
| Writes | `$D726`-`$D727` (`RecordP1+24`); `$D78A`-`$D78B` (`TrackPos`); `$F33E`-`$F71B` (`Trail6Image+270`, `BufferP1Byte`, `BufferP1Rest`); `$FA29`-`$FB71` (`Drums`, `DrumPad`, `DrumJump2`, `DrumJump3` and 17 more); `$FB8E`-`$FBC5` (`NoteTable+28`, `TuneTable`, `SequencesA0`); `$FBE8`-`$FBEB` (`SequencesA0+46`); 10 more ranges |

### `MaskBufferClip` (`$8822`)

**Masked draw of a clipped sprite (ClipWidth bytes a line)**

Witness: L1 1444 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 30 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 807,206 t-states own (0.05 %) |
| Runs (the other recordings) | 1,414 runs of its first instruction, entered by a jump (`stage1/rec/trails` 494, `stage1/rec/warp` 406, `stage1/rec/empty` 158 and 7 more) |
| Called from | `SpriteHeader`, `PlaceClipped` |
| Calls | `PlaceClipped` |
| Reads | `$80E5`-`$80F3` (`DestAddr`, `SpriteNum`, `SpriteData`, `MaskData` and 2 more); `$8115` (`ClipWidth`); `$BE15`-`$C046` (`GameGfx+11961`); `$CC73`-`$CE38` (`GameGfx+15639`); `$F33E`-`$F71B` (`Trail6Image+270`, `BufferP1Byte`, `BufferP1Rest`); `$FA1E`-`$FDFB` (`SetTransposeA+7`, `SetTransposeB`, `Drums`, `DrumPad` and 22 more) |
| Writes | `$F33E`-`$F71B` (`Trail6Image+270`, `BufferP1Byte`, `BufferP1Rest`); `$FA29`-`$FAFD` (`Drums`, `DrumPad`, `DrumJump2`, `DrumJump3` and 13 more); `$FB10`-`$FB26` (`NextSequenceA+23`, `NextSequenceB`); `$FB38`-`$FB3F` (`NextSequenceD+3`); `$FB52`-`$FB71` (`NextSequenceD+29`, `TuneEntry`, `NoteLookup`); `$FB8E`-`$FBC5` (`NoteTable+28`, `TuneTable`, `SequencesA0`); 11 more ranges |

### `MaskBuffer` (`$8862`)

**Masked draw: (buffer OR mask) XOR sprite**

Witness: L1 11643 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 1,202 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 15,921,847 t-states own (1.02 %) |
| Runs (the other recordings) | 10,441 runs of its first instruction, entered by a jump (`stage1/rec/kb` 3,252, `stage1/rec/trails` 1,838, `stage1/rec/warp` 1,688 and 7 more) |
| Called from | `HiScoreScreen`, `DrawAtv`, `DrawRider` |
| Calls | `HiScoreScreen`, `DrawAtv`, `DrawRider` |
| Reads | `$80E5`-`$80F3` (`DestAddr`, `SpriteNum`, `SpriteData`, `MaskData` and 2 more); `$90FA`-`$94E1` (`GameGfx+414`); `$9576`-`$995D` (`GameGfx+1562`); `$9B6C`-`$9C47` (`GameGfx+3088`); `$9F77`-`$B6F4` (`GameGfx+4123`); `$BCAF`-`$BDC6` (`GameGfx+11603`); 3 more ranges |
| Writes | `$F05B`-`$F71B` (`BufferP1+31`, `BufferP1Zeros`, `Trail6Image`, `BufferP1Byte` and 1 more); `$F73B`-`$F73D` (`BufferP2+31`); `$F754`-`$F75F` (`BufferP2+56`); `$F776`-`$F77D` (`BufferP2+90`); `$F7A9`-`$F7B3` (`BufferP2+141`); `$F7EA`-`$FA11` (`BufferP2+206`, `TunePlay0`, `TunePlay`, `TuneLoop` and 8 more); 12 more ranges |

### `MaskMirror` (`$8891`)

**Masked draw mirrored: the bytes and their bits reversed**

Witness: L1 1719 (c1, fuel, trail1, trails, turn, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 2 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 156,524 t-states own (0.01 %) |
| Runs (the other recordings) | 1,717 runs of its first instruction, entered by a jump (`stage1/rec/fuel` 1,021, `stage1/rec/trail1` 506, `stage1/rec/warp` 100 and 2 more) |
| Called from | `HiScoreScreen`, `DrawAtv`, `DrawRider` |
| Calls | `HiScoreScreen`, `AtvMirrorReturn`, `DrawRider` |
| Reads | `$80E5`-`$80F3` (`DestAddr`, `SpriteNum`, `SpriteData`, `MaskData` and 2 more); `$90FA`-`$94E1` (`GameGfx+414`); `$9576`-`$995D` (`GameGfx+1562`); `$9F77`-`$A423` (`GameGfx+4123`); `$A7AD`-`$AC61` (`GameGfx+6225`); `$ACB5`-`$AE60` (`GameGfx+7513`); 3 more ranges |
| Writes | `$F2C2`-`$F2C4` (`Trail6Image+146`); `$F2D8`-`$F70A` (`Trail6Image+168`, `BufferP1Byte`, `BufferP1Rest`) |

### `FlushDeferredA` (`$8906`)

**Draw DeferredA's sprites (after the ATV, in front of it)**

Witness: L1 6679 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 600 calls, 19,572 t-states own (0.00 %) |
| Runs (the other recordings) | 6,079 calls (`stage1/rec/kb` 1,626, `stage1/rec/fuel` 1,254, `stage1/rec/trails` 920 and 7 more) |
| Called from | `JpFlushDeferredA` (tail) |
| Calls | `FlushDeferredB` (tail) |
| Reads | `$8148` (`DeferredA+2`) |

### `FlushDeferredB` (`$8913`)

**Draw DeferredB's sprites (before the ATV, behind it)**

Witness: L1 6679 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 600 calls, 61,838 t-states own (0.00 %) |
| Runs (the other recordings) | 6,079 calls (`stage1/rec/kb` 1,626, `stage1/rec/fuel` 1,254, `stage1/rec/trails` 920 and 7 more) |
| Called from | `JpFlushDeferredB` (tail), `FlushDeferredA` (tail) |
| Calls | `PlaceClipped` |
| Reads | `$8149`-`$8160` (`DeferredA+3`); `$81EB`-`$81FB` (`DeferredB+2`) |
| Writes | `$80DB`-`$80F6` (`SpriteX`, `SpriteY`, `ScreenBase`, `DestAddr` and 7 more); `$811A`-`$8121` (`ClipCode`, `ListBase`, `ListIndexPtr`, `ListScroll` and 1 more); `$82FC`-`$82FD` (`SpriteCall`) |

### `DeferAttrs` (`$894C`)

**An item with attributes: its picture's attributes into DeferredAttrs**

Witness: L1 2139 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 54 calls, 9,126 t-states own (0.00 %) |
| Runs (the other recordings) | 2,085 calls (`stage1/rec/warp` 641, `stage1/rec/trails` 531, `stage1/rec/kb` 284 and 7 more) |
| Called from | `PlaceClipped` (tail) |
| Calls | `JpMenuSpriteAttrs`, `AttrAddrPlay`, `AddDeferredAttr` (tail) |
| Reads | `$80F7`-`$80FA` (`AttrDest`, `AttrSrc`); `$8118`-`$8119` (`ClipSkip`) |
| Writes | `$80F7`-`$80FA` (`AttrDest`, `AttrSrc`); `$82FA`-`$82FB` (`AttrModeVector`) |

### `CopyAttrs` (`$896D`)

**Copy one deferred attribute block to the screen**

Witness: L1 2139 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 54 calls, 22,134 t-states own (0.00 %) |
| Runs (the other recordings) | 2,085 calls (`stage1/rec/warp` 641, `stage1/rec/trails` 531, `stage1/rec/kb` 284 and 7 more) |
| Called from | `FlushAttrs` |
| Reads | `$6516`-`$6533` (`MenuGfx+478`); `$65F0`-`$660D` (`MenuGfx+696`); `$66DB`-`$66E2` (`MenuGfx+931`); `$66F5`-`$66FC` (`MenuGfx+957`); `$80F7`-`$80FC` (`AttrDest`, `AttrSrc`, `AttrWidth`, `AttrHeight`); `$8115`-`$8116` (`ClipWidth`) |
| Writes | `$5901`-`$5916` (screen); `$5A81`-`$5A96` (screen) |

### `FlushAttrs` (`$8995`)

**Copy every deferred attribute block**

Witness: L1 6679 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 600 calls, 31,938 t-states own (0.00 %) |
| Runs (the other recordings) | 6,079 calls (`stage1/rec/kb` 1,626, `stage1/rec/fuel` 1,254, `stage1/rec/trails` 920 and 7 more) |
| Called from | `JpFlushAttrs` (tail) |
| Calls | `CopyAttrs` |
| Reads | `$828E`-`$8295` (`DeferredAttrs+2`) |
| Writes | `$80F7`-`$80FC` (`AttrDest`, `AttrSrc`, `AttrWidth`, `AttrHeight`); `$8115` (`ClipWidth`) |

### `AddDeferredAttr` (`$89C6`)

**Append the attribute variables to DeferredAttrs**

Witness: L1 2139 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 54 calls, 14,850 t-states own (0.00 %) |
| Runs (the other recordings) | 2,085 calls (`stage1/rec/warp` 641, `stage1/rec/trails` 531, `stage1/rec/kb` 284 and 7 more) |
| Called from | `DeferAttrs` (tail) |
| Reads | `$80F7`-`$80FC` (`AttrDest`, `AttrSrc`, `AttrWidth`, `AttrHeight`); `$8115` (`ClipWidth`); `$828C`-`$828E` (`DeferredAttrs`) |
| Writes | `$828C`-`$8295` (`DeferredAttrs`) |

### `DeferA` (`$89F8`)

**Append the sprite's variables to DeferredA**

Witness: L1 6084 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 159 calls, 51,058 t-states own (0.00 %) |
| Runs (the other recordings) | 5,925 calls (`stage1/rec/warp` 1,922, `stage1/rec/trails` 1,224, `stage1/rec/kb` 880 and 7 more) |
| Called from | `WalkList` |
| Calls | `DeferB` (tail) |
| Reads | `$80DB`-`$80F6` (`SpriteX`, `SpriteY`, `ScreenBase`, `DestAddr` and 7 more); `$811A`-`$8121` (`ClipCode`, `ListBase`, `ListIndexPtr`, `ListScroll` and 1 more); `$8146`-`$8148` (`DeferredA`); `$82FC`-`$82FD` (`SpriteCall`) |
| Writes | `$8146`-`$8160` (`DeferredA`) |

### `DeferB` (`$8A0F`)

**Append the sprite's variables to DeferredB**

Witness: L1 182 (warp).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 182 calls (`stage1/rec/warp` 182) |
| Called from | `DeferA` (tail), `WalkList` |
| Reads | `$80DB`-`$80F6` (`SpriteX`, `SpriteY`, `ScreenBase`, `DestAddr` and 7 more); `$811A`-`$8121` (`ClipCode`, `ListBase`, `ListIndexPtr`, `ListScroll` and 1 more); `$81E9`-`$81EB` (`DeferredB`); `$82FC`-`$82FD` (`SpriteCall`) |
| Writes | `$8149`-`$8160` (`DeferredA+3`); `$81E9`-`$81FB` (`DeferredB`) |

### `AnimObject` (`$8A49`)

**An animated item: take its sprite and flags from its record and step the record's motions once a pass**

IY the item, IX its record: +0 sprite, +1 flags, +2 id, then up to three motions of (period, counter): the distance (+3/+4, step in +7's high nibble), y (+5/+6, step in +7's low nibble) and the sprite (+8 period and step, +9 counter). A counter's bit 7 is the direction; it turns at the period. A motion with period `$FF` ends the record, 0 skips it. Each id moves once a pass (SeenIds). Trails 1-4: c1 4449 runs.

Witness: L1 5447 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 108 calls, 30,764 t-states own (0.00 %) |
| Runs (the other recordings) | 5,339 calls (`stage1/rec/warp` 1,696, `stage1/rec/fuel` 1,161, `stage1/rec/trails` 712 and 7 more) |
| Called from | `PlaceItem` |
| Reads | `$60BD`-`$60F9` (system); `$6141`-`$6195` (system); `$6212`-`$62A1` (system); `$7CB9`-`$7D39` (`Trail1ListA+5`, `Trail2ListA`); `$7E11`-`$7E25` (`Trail2ListA+221`, `Trail3ListA`); `$7E76`-`$7EAF` (`Trail3ListA+86`); 6 more ranges |
| Writes | `$60DC`-`$60F6` (system); `$6148`-`$6150` (system); `$616E`-`$618C` (system); `$621A`-`$62A1` (system); `$7E76`-`$7E7C` (`Trail3ListA+86`); `$7EA0`-`$7EAC` (`Trail3ListA+128`); 8 more ranges |

### `ListOverflow` (`$8A90`)

**More than 30 animated objects in a pass: blue border, hang**

Known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PlaceClipped` (`$8BA0`)

**Draw an item by its clip code: whole (OrBuffer / MaskBuffer), cut at the right or at the left**

Witness: L1 43780 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 1,901 calls, 603,027 t-states own (0.04 %) |
| Runs (the other recordings) | 41,879 calls (`stage1/rec/kb` 13,046, `stage1/rec/fuel` 11,210, `stage1/rec/warp` 6,138 and 7 more) |
| Called from | `MaskBufferClip`, `FlushDeferredB`, `OrBufferClip`, `WalkList` |
| Calls | `BufferAddr`, `MaskBufferClip`, `DeferAttrs` (tail), `SpriteGo`, `LoadMask`, `OrBufferClip` |
| Reads | `$80DB`-`$80F6` (`SpriteX`, `SpriteY`, `ScreenBase`, `DestAddr` and 7 more); `$8115`-`$8121` (`ClipWidth`, `ClipSkip`, `ClipCode`, `ListBase` and 3 more); `$836F`-`$8378` (`ListModes+2`) |
| Writes | `$80DB`-`$80F6` (`SpriteX`, `SpriteY`, `ScreenBase`, `DestAddr` and 7 more); `$8115`-`$8119` (`ClipWidth`, `ClipSkip`); `$82F8`-`$82F9` (`ModeVector`) |

### `SpriteGo` (`$8CB2`)

**JP (SpriteCall)**

Witness: L1 119154 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 6,289 calls, 125,799 t-states own (0.01 %) |
| Runs (the other recordings) | 112,865 calls (`stage1/rec/kb` 32,953, `stage1/rec/fuel` 27,560, `stage1/rec/warp` 18,977 and 7 more) |
| Called from | `JpSpriteGo` (tail), `PlaceClipped`, `LoadMask`, `PlaceItem` |
| Calls | `JpGameSprite`, `JpMenuSprite`, `GameSprite`, `MenuSprite` |
| Reads | `$82FC`-`$82FD` (`SpriteCall`) |

### `LoadMask` (`$8CB6`)

**MaskData = the sprite (SpriteNum + the flags' mask offset)'s bytes**

Witness: L1 2213 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 53 calls, 9,593 t-states own (0.00 %) |
| Runs (the other recordings) | 2,160 calls (`stage1/rec/warp` 641, `stage1/rec/trails` 552, `stage1/rec/kb` 322 and 7 more) |
| Called from | `PlaceClipped` |
| Calls | `SpriteGo` |
| Reads | `$80E7`-`$80E9` (`SpriteNum`, `SpriteData`); `$8121` (`ItemFlags`) |
| Writes | `$80E7`-`$80EB` (`SpriteNum`, `SpriteData`, `MaskData`); `$82F8`-`$82F9` (`ModeVector`) |

### `CopyBufferP1` (`$8CDA`)

**Copy BufferP1 to the screen's top half (`$4021`)**

Witness: L1 5870 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 601 calls, 24,040 t-states own (0.00 %) |
| Runs (the other recordings) | 5,269 calls (`stage1/rec/fuel` 1,254, `stage1/rec/trails` 920, `stage1/rec/warp` 894 and 7 more) |
| Called from | `JpCopyBufferP1` (tail) |
| Calls | `CopyLines` (tail) |

### `CopyBufferP2` (`$8CE6`)

**Copy BufferP2 to the bottom half (`$48A1`)**

Witness: L1 814 (kb).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 814 calls (`stage1/rec/kb` 814) |
| Called from | `JpCopyBufferP2` (tail) |
| Calls | `CopyLines` (falls into) |

### `CopyLines` (`$8CF2`)

**Copy BC bytes from HL to the screen at DE, 22 a line (22 LDIs), DE down a line each**

Witness: L1 549760 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

[Animation: `CopyLines` at work](img/routines/CopyLines.gif)

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 668 calls, 24,151,982 t-states own (1.54 %) |
| Runs (the other recordings) | 6,204 calls (`stage1/rec/kb` 1,633, `stage1/rec/fuel` 1,255, `stage1/rec/warp` 940 and 8 more) |
| Called from | `JpCopyLines` (tail), `CopyBufferP1` (tail), `CopyBufferP2` (falls into) |
| Calls | `NextLineDE` |
| Reads | `$F03C`-`$FDFB` (`BufferP1`, `BufferP1Zeros`, `Trail6Image`, `BufferP1Byte` and 39 more) |
| Writes | `$4005`-`$57FB` (screen) |

### `ClearBufferP1` (`$8D28`)

**Zero BufferP1 by PUSH (SP from `$F71C` down)**

Witness: L1 5968 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 612 calls, 6,610,824 t-states own (0.42 %) |
| Runs (the other recordings) | 5,356 calls (`stage1/rec/fuel` 1,256, `stage1/rec/trails` 925, `stage1/rec/warp` 919 and 8 more) |
| Called from | `JpClearBufferP1` (tail) |
| Calls | `ClearBufferP2` (tail) |
| Reads | `$8142`-`$8143` (`SavedSp`) |
| Writes | `$8142`-`$8143` (`SavedSp`) |

### `ClearBufferP2` (`$8D32`)

**Zero BufferP2 (SP from `$FDFC`)**

Witness: L1 813 (kb).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 813 calls (`stage1/rec/kb` 813) |
| Called from | `JpClearBufferP2` (tail), `ClearBufferP1` (tail) |
| Reads | `$8142`-`$8143` (`SavedSp`) |
| Writes | `$8142`-`$8143` (`SavedSp`); `$F656`-`$F661` (`BufferP1Rest+411`); `$F678`-`$F681` (`BufferP1Rest+445`); `$F8A6`-`$F8A7` (`l_F890+22`); `$FB10`-`$FB45` (`NextSequenceA+23`, `NextSequenceB`, `NextSequenceD`); `$FC28`-`$FC29` (`SequencesA0+110`); 1 more ranges |

### `OrBuffer` (`$8D53`)

**OR a sprite into the buffer**

Witness: L1 43014 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 1,630 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 3,643,011 t-states own (0.23 %) |
| Runs (the other recordings) | 41,384 runs of its first instruction, entered by a jump (`stage1/rec/trails` 11,903, `stage1/rec/kb` 10,079, `stage1/rec/fuel` 8,604 and 8 more) |
| Called from | `SpriteHeader` |
| Reads | `$650C`-`$66F2` (`MenuGfx+468`); `$80E5`-`$80F3` (`DestAddr`, `SpriteNum`, `SpriteData`, `MaskData` and 2 more); `$99F4`-`$9F6C` (`GameGfx+2712`); `$B6FF`-`$B776` (`GameGfx+10147`); `$BA1A`-`$BA37` (`GameGfx+10942`); `$BA4C`-`$BA5D` (`GameGfx+10992`); 6 more ranges |
| Writes | `$F0F8`-`$F71C` (`BufferP1+188`, `BufferP1Zeros`, `Trail6Image`, `BufferP1Byte` and 2 more); `$F7E8`-`$F8A1` (`BufferP2+204`, `TunePlay0`, `TunePlay`); `$F939`-`$FA11` (`l_F916+35`, `TuneInterrupt`, `TuneKeyCheck`, `ChannelBCommand` and 5 more); `$FA29`-`$FB71` (`Drums`, `DrumPad`, `DrumJump2`, `DrumJump3` and 17 more); `$FB8E`-`$FBC5` (`NoteTable+28`, `TuneTable`, `SequencesA0`); `$FBE8`-`$FBEB` (`SequencesA0+46`); 10 more ranges |

### `OrBufferClip` (`$8D76`)

**OR a clipped sprite into the buffer**

Witness: L1 12410 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 655 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 2,662,408 t-states own (0.17 %) |
| Runs (the other recordings) | 11,755 runs of its first instruction, entered by a jump (`stage1/rec/kb` 3,258, `stage1/rec/fuel` 2,524, `stage1/rec/trails` 1,867 and 7 more) |
| Called from | `SpriteHeader`, `PlaceClipped` |
| Calls | `PlaceClipped` |
| Reads | `$650C`-`$66F2` (`MenuGfx+468`); `$80E5`-`$80F3` (`DestAddr`, `SpriteNum`, `SpriteData`, `MaskData` and 2 more); `$8115` (`ClipWidth`); `$99F4`-`$9DCC` (`GameGfx+2712`); `$B6FF`-`$B776` (`GameGfx+10147`); `$B7B7`-`$B85D` (`GameGfx+10331`); 11 more ranges |
| Writes | `$D726`-`$D727` (`RecordP1+24`); `$D78A`-`$D78B` (`TrackPos`); `$F25F`-`$F261` (`Trail6Image+47`); `$F275`-`$F277` (`Trail6Image+69`); `$F28B`-`$F355` (`Trail6Image+91`); `$F367`-`$F71B` (`Trail6Image+311`, `BufferP1Byte`, `BufferP1Rest`); 15 more ranges |

### `WalkList` (`$8DA3`)

**Draw a trail list: skip the items behind, draw the ones on screen, stop at the first beyond**

ListBase the list, ListIndexPtr its index word (the first item not yet behind), ListScroll the distance. From the index item each item goes through PlaceItem: 2 (behind the left edge) moves the index on by 6, 1 (beyond the right edge) ends the walk; drawn items go to PlaceClipped or a deferred list by ItemFlags. Twice a pass a player (DistanceIndex for list A, ScenIndex for list B).

Witness: L1 13363 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

[Animation: `WalkList` at work](img/routines/WalkList.gif)

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 1,200 calls, 707,021 t-states own (0.05 %) |
| Runs (the other recordings) | 12,161 calls (`stage1/rec/kb` 3,252, `stage1/rec/fuel` 2,508, `stage1/rec/trails` 1,842 and 7 more) |
| Called from | `JpWalkList` (tail) |
| Calls | `DeferA`, `DeferB`, `PlaceClipped`, `NextIndex`, `PlaceItem` |
| Reads | `$60B3`-`$61C9` (system); `$7CB5`-`$8023` (`Trail1ListA+1`, `Trail2ListA`, `Trail3ListA`, `Trail4ListA` and 4 more); `$811B`-`$8121` (`ListBase`, `ListIndexPtr`, `ListScroll`, `ItemFlags`); `$D78C`-`$D792` (`DistanceIndex`, `Scenery`, `SceneryPos`, `ScenIndex`); `$EE8B`-`$EF5F` (`Trail5+7`) |
| Writes | `$D78C`-`$D78D` (`DistanceIndex`) |

### `NextIndex` (`$8E2B`)

**The index word + 6**

Witness: L1 306 (c1, fuel, kb, speedcrash, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 2 calls, 224 t-states own (0.00 %) |
| Runs (the other recordings) | 304 calls (`stage1/rec/warp` 160, `stage1/rec/kb` 62, `stage1/rec/trails` 36 and 5 more) |
| Called from | `WalkList` |
| Reads | `$811D`-`$811E` (`ListIndexPtr`); `$D78C`-`$D792` (`DistanceIndex`, `Scenery`, `SceneryPos`, `ScenIndex`) |
| Writes | `$D78C`-`$D792` (`DistanceIndex`, `Scenery`, `SceneryPos`, `ScenIndex`) |

### `PlaceItem` (`$8E3C`)

**Set up an item: its sprite (or AnimObject's), flags, y, advance; x = its distance - ListScroll; the clip code**

A = 0 inside, 1 beyond the right (x > `$AF`), 2 behind the left, 3 / 4 cut at an edge. A y below the sprite's height is a broken list: ItemTooLow. The measuring call at `$8EA4` runs before SpriteX is set: it shifts the sprite to the previous item's x, and the real draw shifts it back; 15-29 % of a pass (c1 15356).

Witness: L1 72404 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 4,306 calls, 2,580,836 t-states own (0.16 %) |
| Runs (the other recordings) | 68,098 calls (`stage1/rec/kb` 19,508, `stage1/rec/fuel` 16,239, `stage1/rec/warp` 11,875 and 7 more) |
| Called from | `WalkList` |
| Calls | `AnimObject`, `SpriteGo` |
| Reads | `$60B2`-`$61CD` (system); `$7CB4`-`$8027` (`Trail1ListA`, `Trail2ListA`, `Trail3ListA`, `Trail4ListA` and 4 more); `$80DD` (`SpriteY`); `$80F3`-`$80F6` (`SpriteHeight`, `ShiftPtr`, `SpriteAdvance`); `$811F`-`$8121` (`ListScroll`, `ItemFlags`); `$EE8A`-`$EF63` (`Trail5+6`) |
| Writes | `$80DB`-`$80F6` (`SpriteX`, `SpriteY`, `ScreenBase`, `DestAddr` and 7 more); `$811A`-`$8121` (`ClipCode`, `ListBase`, `ListIndexPtr`, `ListScroll` and 1 more); `$82F8`-`$82FD` (`ModeVector`, `AttrModeVector`, `SpriteCall`) |

### `PlaceItemDead` (`$8EBC`)

**Two instructions no path reaches (SpriteY = SpriteHeight)**

Known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PlaceItemX` (`$8EC2`)

**x and the clip code**

Witness: L1 72404 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 4,306 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 68,098 runs of its first instruction, entered by a jump (`stage1/rec/kb` 19,508, `stage1/rec/fuel` 16,239, `stage1/rec/warp` 11,875 and 7 more) |

### `ClipY` (`$DBD1`)

**A = y; clip a sprite at the play area's top (y `$50`): drop the lines above it**

Witness: L1 20900 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 1,294 calls, 97,242 t-states own (0.01 %) |
| Runs (the other recordings) | 19,606 calls (`stage1/rec/kb` 5,912, `stage1/rec/trails` 3,388, `stage1/rec/warp` 2,880 and 7 more) |
| Called from | `AtvY` (tail), `RiderY` (tail), `WheelY` (tail) |
| Calls | `JpBufferAddr`, `ClipTop` |
| Writes | `$80DD`-`$80E6` (`SpriteY`, `ScreenBase`, `DestAddr`) |

### `ClipTop` (`$DBE2`)

**Cut the sprite's lines above the play area**

Witness: L1 85 (c1, fuel, kb, trail1, trails, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 16 calls, 3,264 t-states own (0.00 %) |
| Runs (the other recordings) | 69 calls (`stage1/rec/kb` 24, `stage1/rec/warp` 21, `stage1/rec/wallcrash` 15 and 3 more) |
| Called from | `ClipY` |
| Calls | `JpMultiply` |
| Reads | `$80E8`-`$80F3` (`SpriteData`, `MaskData`, `SpriteWidth`, `SpriteHeight`) |
| Writes | `$80E8`-`$80F3` (`SpriteData`, `MaskData`, `SpriteWidth`, `SpriteHeight`) |

### `AtvY` (`$DC13`)

**The ATV sprite's y from its height and frame (the tumble's offsets, the nose-down frames' WheelOffsets)**

Witness: L1 6679 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 600 calls, 75,238 t-states own (0.00 %) |
| Runs (the other recordings) | 6,079 calls (`stage1/rec/kb` 1,626, `stage1/rec/fuel` 1,254, `stage1/rec/trails` 920 and 7 more) |
| Called from | `DrawAtv` |
| Calls | `ClipY` (tail) |
| Reads | `$80F3` (`SpriteHeight`); `$D775`-`$D778` (`AtvFrame`, `Facing`, `AtvX`, `AtvHeight`); `$DC0D`-`$DC12` (`TumbleOffsets`); `$E62A`-`$E630` (`WheelOffsets+15`) |
| Writes | `$80DD` (`SpriteY`) |

### `RiderY` (`$DC6E`)

**The rider sprite's y from his height**

Witness: L1 6675 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 600 calls, 33,000 t-states own (0.00 %) |
| Runs (the other recordings) | 6,075 calls (`stage1/rec/kb` 1,626, `stage1/rec/fuel` 1,254, `stage1/rec/trails` 920 and 7 more) |
| Called from | `DrawRider` |
| Calls | `ClipY` (tail) |
| Reads | `$80F3` (`SpriteHeight`); `$D786` (`RiderHeight`) |

### `DrawAtvAndRider` (`$DC82`)

**DrawAtv, then DrawRider**

Witness: L1 6679 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 600 calls, 16,200 t-states own (0.00 %) |
| Runs (the other recordings) | 6,079 calls (`stage1/rec/kb` 1,626, `stage1/rec/fuel` 1,254, `stage1/rec/trails` 920 and 7 more) |
| Called from | `Update` |
| Calls | `DrawAtv`, `DrawRider` (tail) |

### `DrawAtv` (`$DC88`)

**The ATV: body and wheels, mirrored when it faces left**

Facing left, LD A,E drops the XOR 7 that DrawRider keeps (OR E at `$DDF3`): the left-facing ATV is drawn at x AND `$F8`.

Witness: L1 6679 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

[Animation: `DrawAtv` at work](img/routines/DrawAtv.gif)

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 600 calls, 274,219 t-states own (0.02 %) |
| Runs (the other recordings) | 6,079 calls (`stage1/rec/kb` 1,626, `stage1/rec/fuel` 1,254, `stage1/rec/trails` 920 and 7 more) |
| Called from | `MaskBuffer`, `DrawAtvAndRider` |
| Calls | `JpGameSprite`, `MaskBuffer`, `MaskMirror`, `AtvY`, `Wheels` (tail) |
| Reads | `$80DB`-`$80F3` (`SpriteX`, `SpriteY`, `ScreenBase`, `DestAddr` and 5 more); `$8371`-`$8374` (`ListModes+4`); `$D775`-`$D777` (`AtvFrame`, `Facing`, `AtvX`) |
| Writes | `$80DB`-`$80F3` (`SpriteX`, `SpriteY`, `ScreenBase`, `DestAddr` and 5 more); `$82F8`-`$82F9` (`ModeVector`) |

### `AtvMirrorReturn` (`$DD45`)

**MaskMirror's return when DrawAtv faces left (DrawAtv pushes it before JP (HL)): x + 8, sprite `$79`, JP Wheels**

Known only from the code.

Witness: L1 45 (turn).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 45 calls (`stage1/rec/turn` 45) |
| Called from | `MaskMirror` |
| Calls | `Wheels` (falls into) |
| Reads | `$80DB` (`SpriteX`) |
| Writes | `$80DB`-`$80E7` (`SpriteX`, `SpriteY`, `ScreenBase`, `DestAddr` and 1 more) |

### `Wheels` (`$DD55`)

**The wheels under the body for the upright frames (`$38-$4F`)**

Witness: L1 6679 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 600 calls, 47,918 t-states own (0.00 %) |
| Runs (the other recordings) | 6,079 calls (`stage1/rec/kb` 1,626, `stage1/rec/fuel` 1,254, `stage1/rec/trails` 920 and 7 more) |
| Called from | `ModeXorBuffer`, `DrawAtv` (tail), `AtvMirrorReturn` (falls into) |
| Calls | `ModeXorBuffer`, `JpGameSprite`, `WheelY` |
| Reads | `$6A01`-`$6A02` (`DrawModes+10`); `$80E7` (`SpriteNum`); `$D775` (`AtvFrame`); `$D79A` (`EngineNote`) |
| Writes | `$80E7` (`SpriteNum`) |

### `WheelY` (`$DD84`)

**The wheels' y**

Witness: L1 7546 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 94 calls, 5,170 t-states own (0.00 %) |
| Runs (the other recordings) | 7,452 calls (`stage1/rec/kb` 2,660, `stage1/rec/trails` 1,548, `stage1/rec/trail1` 1,112 and 7 more) |
| Called from | `Wheels` |
| Calls | `ClipY` (tail) |
| Reads | `$80F3` (`SpriteHeight`); `$D778` (`AtvHeight`) |

### `DrawRider` (`$DD96`)

**The rider: walking, riding, thrown or lying, mirrored by RiderFacing**

Witness: L1 6679 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 600 calls, 239,694 t-states own (0.02 %) |
| Runs (the other recordings) | 6,079 calls (`stage1/rec/kb` 1,626, `stage1/rec/fuel` 1,254, `stage1/rec/trails` 920 and 7 more) |
| Called from | `MaskBuffer`, `MaskMirror`, `DrawAtvAndRider` (tail), `RiderGround`, `FallRider`, `RiderToGround`, `Thrown` |
| Calls | `JpGameSprite`, `MaskBuffer`, `MaskMirror`, `RiderY` |
| Reads | `$80E5`-`$80E9` (`DestAddr`, `SpriteNum`, `SpriteData`); `$8371`-`$8374` (`ListModes+4`); `$D775`-`$D786` (`AtvFrame`, `Facing`, `AtvX`, `AtvHeight` and 12 more) |
| Writes | `$80DB`-`$80EB` (`SpriteX`, `SpriteY`, `ScreenBase`, `DestAddr` and 3 more); `$82F8`-`$82F9` (`ModeVector`); `$D787`-`$D788` (`RiderSavedX`, `RiderSavedHeight`) |

## scores

`src/game/scores.asm`

### `CheckHiScore` (`$7A3E`)

**After a game: each player's score into the table when it beats a row, with the name entry**

Player 1 against the five rows (HiCompare); in a two-player game player 2 too. A place: NameEntry with the player's reader (ReadP1 `$7BBE` or ReadP2 `$7BC2`) patched into ReadControlJump. Called through JpCheckHiScore by GameEntry's outer loop after each game (c1: 4 runs, 2 places). Player 1, when he reaches only the last row, is skipped unless he beat player 2.

Witness: L1 4 (c1, kb, trail1, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 1 call, 178 t-states own (0.00 %) |
| Runs (the other recordings) | 3 calls (`stage1/rec/kb` 1, `stage1/rec/warp` 1, `stage1/rec/trail1` 1) |
| Called from | `JpCheckHiScore` (tail) |
| Calls | `ClearScreen`, `NameEntry` (falls into), `HiCompare` |
| Reads | `$694D`-`$6957` (`ScoreP2`, `NameColour`, `NameRow`, `NameScorePtr` and 1 more); `$6968` (`BigChar`); `$6982`-`$6985` (`HiNames+24`); `$80DD` (`SpriteY`) |
| Writes | `$6952`-`$6968` (`NameColour`, `HiScoreTitle`); `$6982`-`$6986` (`HiNames+24`); `$69A0`-`$69A4` (`HiScores+24`); `$7BBC`-`$7BBD` (`ReadControlJump+1`); `$80DB`-`$80DD` (`SpriteX`, `SpriteY`); `$82F8`-`$82F9` (`ModeVector`) |
| Ports out | `$05FE` |

### `NameEntry` (`$7A7E`)

**Insert the score at its row (moving the rows below down), then enter the name on a letter grid**

A the row (HiCompare). The scores and names below move down by LDDR, the score goes in, the name is blanked; the screen shows the table, the grid of letters A-Z, space and the end mark (4 rows of 7), a cursor moved by the player's controls (left/right/up/down), fire takes the letter under it into the name; the end mark returns.

Witness: L1 5 (c1, kb, trail1, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 2 calls (`stage1/rec/warp` 2) |
| Called from | `CheckHiScore` (falls into), `ReadControlRaw` (tail) |
| Calls | `MenuRedraw`, `Print`, `FillAttrsBase`, `ReadControl`, `NameCursor`, `ShowBufferPlace`, `NameScreen`, `HiCompare`, `JpMultiply`, `JpClearBufferP1` |
| Reads | `$6948`-`$699F` (`Scores`, `HiScoreTitle`, `HiNames`, `HiScores`); `$80DD` (`SpriteY`); `$D6C3` (`PassControls`) |
| Writes | `$6953`-`$69A5` (`NameRow`, `HiScoreTitle`, `HiNames`, `HiScores`); `$7BBC`-`$7BBD` (`ReadControlJump+1`); `$80DB`-`$80DD` (`SpriteX`, `SpriteY`); `$82F8`-`$82F9` (`ModeVector`) |
| Ports out | `$02FE` |

### `ReadControl` (`$7BA2`)

**Wait for the controls to be released, then pressed: A the bits**

Witness: L1 260961 (kb, warp).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 13 calls (`stage1/rec/warp` 12, `stage1/rec/kb` 1) |
| Called from | `NameEntry` |
| Calls | `ReadControlRaw` |
| Reads | `$6956`-`$696E` (`NameTextPtr`, `HiScoreTitle`, `HiNames`) |
| Writes | `$696A`-`$696E` (`HiNames`); `$D6C3` (`PassControls`) |

### `ReadControlRaw` (`$7BB8`)

**Scan the keyboard, then the player's reader**

Witness: L1 336036 (kb, warp).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 336,036 calls (`stage1/rec/warp` 237,613, `stage1/rec/kb` 98,423) |
| Called from | `ReadControl` |
| Calls | `CellCount`, `NameEntry` (tail), `NameScreen`, `JpClearKeys`, `JpMultiply` |
| Reads | `$8113`-`$8114` (`Controls1`, `Controls2`) |

### `NameCursor` (`$7BFE`)

**Colour the cursor's 2 x 2 cells with A**

Witness: L1 22 (kb, warp).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 22 calls (`stage1/rec/warp` 21, `stage1/rec/kb` 1) |
| Called from | `NameEntry` |
| Calls | `FillAttrs` (tail) |
| Reads | `$695C`-`$695D` (`CursorPos`) |

### `ShowBufferPlace` (`$7C07`)

**Show the buffer at the screen place H = x, L = y**

Witness: L1 33 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 3 calls, 149 t-states own (0.00 %) |
| Runs (the other recordings) | 30 calls (`stage1/rec/warp` 13, `stage1/rec/kb` 4, `stage1/rec/menu` 2 and 8 more) |
| Called from | `TrailIntro`, `Credits` (tail), `NameEntry`, `NameScreen` (tail) |
| Calls | `ShowBufferAt` (tail), `ScreenAddrHL` |

### `ScreenAddrHL` (`$7C11`)

**SpriteX = H, SpriteY = L, HL = the screen address (ScreenAddr)**

Witness: L1 137 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 13 calls, 625 t-states own (0.00 %) |
| Runs (the other recordings) | 124 calls (`stage1/rec/warp` 48, `stage1/rec/kb` 18, `stage1/rec/trails` 10 and 8 more) |
| Called from | `TrailIntro`, `PanelP2`, `PanelP1`, `ShowAt284F`, `TrailListScreen`, `ClearBottomHalf`, `ShowBufferPlace` |
| Calls | `GfxTable` (tail) |
| Writes | `$80DB`-`$80DD` (`SpriteX`, `SpriteY`) |

### `NameScreen` (`$7C1C`)

**The name entry's screen: the score, the name, "HI SCORE", the colours**

Witness: L1 4 (kb, warp).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 4 calls (`stage1/rec/warp` 3, `stage1/rec/kb` 1) |
| Called from | `NameEntry`, `ReadControlRaw` |
| Calls | `PrintAt`, `FillAttrs`, `ShowBufferPlace` (tail), `JpClearBufferP1` |
| Reads | `$6952`-`$6957` (`NameColour`, `NameRow`, `NameScorePtr`, `NameTextPtr`) |
| Writes | `$6958`-`$695A` (`BigScaleX`, `BigScaleY`, `BigRepeat`); `$82F8`-`$82F9` (`ModeVector`) |

### `HiCompare` (`$7C71`)

**Compare a score (HL) with the five rows (DE): Z when it beats none, else A = 5 - the row**

Witness: L1 10 (c1, kb, trail1, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 2 calls, 1,474 t-states own (0.00 %) |
| Runs (the other recordings) | 8 calls (`stage1/rec/kb` 3, `stage1/rec/warp` 3, `stage1/rec/trail1` 2) |
| Called from | `CheckHiScore`, `NameEntry` |
| Reads | `$6948`-`$6953` (`Scores`, `ScoreP2`, `NameColour`, `NameRow`); `$6988`-`$69A2` (`HiScores`) |

### `DigitsValue` (`$DBB0`)

**HL = the number of the three ASCII digits at IX**

Witness: L1 22 (kb, trails, wallcrash, warp).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 22 calls (`stage1/rec/warp` 14, `stage1/rec/kb` 4, `stage1/rec/trails` 2 and 1 more) |
| Called from | `Update` |
| Calls | `JpMultiply` |
| Reads | `$D6C9`-`$D6CE` (`Clock`, `ClockTens`, `ClockUnits`, `MaxTime`) |

### `ClockDigit` (`$EABF`)

**Draw a clock digit (sprite A - `$97`)**

Witness: L1 5889 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 601 calls, 18,030 t-states own (0.00 %) |
| Runs (the other recordings) | 5,288 calls (`stage1/rec/fuel` 1,255, `stage1/rec/trails` 923, `stage1/rec/warp` 901 and 7 more) |
| Called from | `ShowClock`, `ClockTick` (tail) |
| Calls | `BigDigit` (tail) |

### `BigDigit` (`$EAC4`)

**Draw a HUD digit (sprite A - `$A3`)**

Witness: L1 548 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 70 calls, 34,810 t-states own (0.00 %) |
| Runs (the other recordings) | 478 calls (`stage1/rec/warp` 121, `stage1/rec/trails` 109, `stage1/rec/kb` 97 and 7 more) |
| Called from | `ClockDigit` (tail), `ShowMaxTime` (tail), `ShowClock` (tail), `ClockTick` (tail) |
| Calls | `JpGameSpriteAt` |
| Writes | `$80E7` (`SpriteNum`) |

### `ShowMaxTime` (`$EACF`)

**MaxTime from MaxTimes (or "30" in the second round) and its digits**

Witness: L1 21 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 1 call, 298 t-states own (0.00 %) |
| Runs (the other recordings) | 20 calls (`stage1/rec/warp` 8, `stage1/rec/kb` 2, `stage1/rec/trails` 2 and 7 more) |
| Called from | `JpShowMaxTime` (tail) |
| Calls | `BigDigit` (tail), `ClockPlace` |
| Reads | `$80DB` (`SpriteX`); `$D6BF`-`$D6DA` (`Trail`, `FinishDistance`, `HudY`, `PassControls` and 6 more); `$D7A6` (`SecondRound`) |
| Writes | `$80DB` (`SpriteX`); `$82F8`-`$82F9` (`ModeVector`); `$D6CC`-`$D6CD` (`MaxTime`) |

### `ShowClock` (`$EB18`)

**The clock's three digits**

Witness: L1 21 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 1 call, 168 t-states own (0.00 %) |
| Runs (the other recordings) | 20 calls (`stage1/rec/warp` 8, `stage1/rec/kb` 2, `stage1/rec/trails` 2 and 7 more) |
| Called from | `JpShowClock` (tail) |
| Calls | `ClockDigit`, `BigDigit` (tail), `ClockPlace` |
| Reads | `$80DB` (`SpriteX`); `$D6C9`-`$D6CB` (`Clock`, `ClockTens`, `ClockUnits`) |
| Writes | `$80DB` (`SpriteX`) |

### `ClockPlace` (`$EB3C`)

**The clock's place (x `$60`, y `$66`) and its draw mode**

Witness: L1 5910 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 602 calls, 61,404 t-states own (0.00 %) |
| Runs (the other recordings) | 5,308 calls (`stage1/rec/fuel` 1,256, `stage1/rec/trails` 925, `stage1/rec/warp` 909 and 7 more) |
| Called from | `ShowMaxTime`, `ShowClock`, `ClockTick` |
| Writes | `$80DB`-`$80E0` (`SpriteX`, `SpriteY`, `ScreenBase`); `$82F8`-`$82F9` (`ModeVector`) |

### `ClockTick` (`$EB53`)

**Clock + 1 (the last digit each pass, carried into the others) and its digits**

Witness: L1 5868 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

[Animation: `ClockTick` at work](img/routines/ClockTick.gif)

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 600 calls, 48,120 t-states own (0.00 %) |
| Runs (the other recordings) | 5,268 calls (`stage1/rec/fuel` 1,254, `stage1/rec/trails` 921, `stage1/rec/warp` 893 and 7 more) |
| Called from | `NewGame` |
| Calls | `ClockDigit` (tail), `BigDigit` (tail), `ClockPlace` |
| Reads | `$80DB` (`SpriteX`); `$D6C9`-`$D6CB` (`Clock`, `ClockTens`, `ClockUnits`) |
| Writes | `$80DB` (`SpriteX`); `$D6C9`-`$D6CB` (`Clock`, `ClockTens`, `ClockUnits`) |

### `ShowBars` (`$EBA5`)

**Fuel = `$2000`, the FUEL bar drawn full (two 3-pixel cells a byte, 4 lines); not scale ticks**

Witness: L1 23 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 1 call, 352 t-states own (0.00 %) |
| Runs (the other recordings) | 22 calls (`stage1/rec/warp` 8, `stage1/rec/kb` 4, `stage1/rec/trails` 2 and 7 more) |
| Called from | `JpShowBars` (tail) |
| Calls | `GfxTable`, `ScaleLeft`, `ScaleRight` |
| Reads | `$D6C2` (`HudY`) |
| Writes | `$80DB`-`$80DD` (`SpriteX`, `SpriteY`); `$D77C`-`$D77F` (`Fuel`, `SpeedBarLen`, `FuelBar`) |

### `ScaleLeft` (`$EBCD`)

**A scale mark's left half**

Witness: L1 92 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 4 calls, 148 t-states own (0.00 %) |
| Runs (the other recordings) | 88 calls (`stage1/rec/warp` 32, `stage1/rec/kb` 16, `stage1/rec/trails` 8 and 7 more) |
| Called from | `ShowBars` |
| Calls | `ScaleRight` (tail) |

### `ScaleRight` (`$EBD4`)

**A scale mark's right half**

Witness: L1 92 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 4 calls, 1,814 t-states own (0.00 %) |
| Runs (the other recordings) | 88 calls (`stage1/rec/warp` 32, `stage1/rec/kb` 16, `stage1/rec/trails` 8 and 7 more) |
| Called from | `ShowBars`, `ScaleLeft` (tail) |
| Calls | `JpNextLineHL` |
| Reads | `$4212`-`$4215` (screen); `$4312`-`$4315` (screen); `$4412`-`$4415` (screen); `$4512`-`$4515` (screen); `$52F2`-`$52F5` (screen); `$53F2`-`$53F5` (screen); 2 more ranges |
| Writes | `$4212`-`$4215` (screen); `$4312`-`$4315` (screen); `$4412`-`$4415` (screen); `$4512`-`$4515` (screen); `$52F2`-`$52F5` (screen); `$53F2`-`$53F5` (screen); 2 more ranges |

### `TimeOut` (`$EBE3`)

**"TIME OUT" in each riding half that has not finished**

Witness: L1 5 (c1, kb, trail1, trails, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 1 call, 145 t-states own (0.00 %) |
| Runs (the other recordings) | 4 calls (`stage1/rec/kb` 1, `stage1/rec/trail1` 1, `stage1/rec/warp` 1 and 1 more) |
| Called from | `RecordFieldP2` |
| Calls | `JpCopyBufferP1`, `JpCopyBufferP2` (tail), `TimeOutText` |
| Reads | `$D6BE` (`Riding`); `$D7A5` (`Finished`) |
| Writes | `$8144`-`$8145` (`BufferBase`) |

### `TimeOutText` (`$EC15`)

**"TIME OUT" at x `$40`, y `$44`**

Witness: L1 5 (c1, kb, trail1, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 1 call, 261 t-states own (0.00 %) |
| Runs (the other recordings) | 4 calls (`stage1/rec/kb` 2, `stage1/rec/trail1` 1, `stage1/rec/warp` 1) |
| Called from | `TimeOut` |
| Calls | `PrintShadow` (falls into) |
| Reads | `$80DB`-`$80DD` (`SpriteX`, `SpriteY`) |
| Writes | `$80DB`-`$80DD` (`SpriteX`, `SpriteY`); `$82F8`-`$82F9` (`ModeVector`) |

### `PrintShadow` (`$EC26`)

**Print in ModeCopyBuffer (DrawModes + 8: each glyph's box replaces the buffer, a cleared band, the letters cut), then Print in OR (ListModes + 0) at the same x, y**

Witness: L1 1184 (c1, empty, kb, trail1, trails, wallcrash, warp).

[Animation: `PrintShadow` at work](img/routines/PrintShadow.gif)

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 1 run of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 1,182 calls (`stage1/rec/trails` 806, `stage1/rec/warp` 217, `stage1/rec/empty` 83 and 2 more) |
| Called from | `Update` (tail), `FuelBarStep` (tail), `TimeOutText` (falls into) |
| Calls | `JpPrint` (tail) |
| Reads | `$80DB`-`$80DD` (`SpriteX`, `SpriteY`) |
| Writes | `$80DB`-`$80DD` (`SpriteX`, `SpriteY`); `$82F8`-`$82F9` (`ModeVector`) |

### `ScoreUpP1` (`$EDBB`)

**Player 1's score + 1 (ASCII, carried): +1 point, shown as +10 (the units digit is never changed)**

Witness: L1 4269 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 23 calls, 3,439 t-states own (0.00 %) |
| Runs (the other recordings) | 4,246 calls (`stage1/rec/warp` 3,338, `stage1/rec/trails` 341, `stage1/rec/kb` 327 and 7 more) |
| Called from | `ScoreStep` (tail), `BonusP1` (tail) |
| Calls | `ScoreDownP2` (tail) |
| Reads | `$6948`-`$694B` (`Scores`) |
| Writes | `$6948`-`$694B` (`Scores`) |

### `ScoreUpP2` (`$EDC3`)

**Player 2's score + 1: +1 point, shown as +10**

Witness: L1 327 (kb).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 327 calls (`stage1/rec/kb` 327) |
| Called from | `ScoreStep` (tail), `BonusP2` (tail) |
| Calls | `ScoreDownP2` (tail) |

### `ScoreDownP1` (`$EDCB`)

**Player 1's score - 1**

Witness: L1 25 (fuel, kb, speedcrash, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 25 calls (`stage1/rec/turn` 17, `stage1/rec/warp` 3, `stage1/rec/fuel` 2 and 3 more) |
| Called from | `ScoreDown` (tail) |
| Calls | `ScoreDownP2` (tail) |
| Reads | `$694A`-`$694B` (`Scores+2`) |
| Writes | `$694A`-`$694B` (`Scores+2`) |

### `ScoreDownP2` (`$EDD3`)

**Player 2's score - 1**

Witness: L1 1 (kb).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 1 call (`stage1/rec/kb` 1) |
| Called from | `ScoreDown` (tail), `ScoreUpP1` (tail), `ScoreUpP2` (tail), `ScoreDownP1` (tail) |
| Calls | `ScoreDigit` (tail), `ScoreDigitLeft`, `ShowScore` |
| Reads | `$6949`-`$6950` (`Scores+1`, `ScoreP2`) |
| Writes | `$6949`-`$6950` (`Scores+1`, `ScoreP2`) |

### `ScoreDigit` (`$EE1E`)

**Draw the score digit at IX (XOR); not per player**

Witness: L1 10250 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 50 calls, 4,421 t-states own (0.00 %) |
| Runs (the other recordings) | 10,200 calls (`stage1/rec/warp` 7,420, `stage1/rec/kb` 1,452, `stage1/rec/trails` 756 and 7 more) |
| Called from | `ScoreDownP2` (tail) |
| Calls | `JpGameSpriteAt`, `CountBonus` |
| Reads | `$6948`-`$6950` (`Scores`, `ScoreP2`) |
| Writes | `$80E7` (`SpriteNum`) |

### `ScoreDigitLeft` (`$EE2C`)

**IX - 1, x - 7: the next digit to the left, then ScoreDigit; not per player**

Witness: L1 503 (c1, fuel, kb, speedcrash, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 2 calls, 106 t-states own (0.00 %) |
| Runs (the other recordings) | 501 calls (`stage1/rec/warp` 369, `stage1/rec/kb` 70, `stage1/rec/trails` 37 and 5 more) |
| Called from | `ScoreDownP2` |
| Reads | `$80DB` (`SpriteX`) |
| Writes | `$80DB` (`SpriteX`) |

### `ShowScore` (`$EE37`)

**The five digits at IX**

Witness: L1 4622 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

[Animation: `ShowScore` at work](img/routines/ShowScore.gif)

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 23 calls, 2,185 t-states own (0.00 %) |
| Runs (the other recordings) | 4,599 calls (`stage1/rec/warp` 3,341, `stage1/rec/kb` 656, `stage1/rec/trails` 341 and 7 more) |
| Called from | `ScoreDownP2` |
| Writes | `$80DB`-`$80E0` (`SpriteX`, `SpriteY`, `ScreenBase`); `$82F8`-`$82F9` (`ModeVector`) |

## loop

`src/game/loop.asm`

### `EntryJumps` (`$D6B0`)

**JP GameEntry; JP Restart**

The loader enters at `$D6B0` (c1 frame 14 100); ItemTooLow jumps to Restart at `$D6B3`.

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 1 call, 10 t-states own (0.00 %) |
| Calls | `GameEntry` (tail) |

### `GameTable` (`$D6DB`)

**The game's jump table; the first entry JP TrailEnd**

The entries at `$D6DE`, `$D6ED`, `$D6F0`, `$D6F3`, `$D6FC`, `$D702`, `$D705` and `$D708` are called by no one (known only from the code; `$D702` is JP `$0000`).

Known only from the code: no recording runs it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `JpNewGame` (`$D6DE`)

**JP NewGame**

Known only from the code: no recording runs it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `JpLoadRecordP1` (`$D6E1`)

**JP LoadRecordP1**

Witness: L1 21 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 1 call, 10 t-states own (0.00 %) |
| Runs (the other recordings) | 20 calls (`stage1/rec/warp` 8, `stage1/rec/kb` 2, `stage1/rec/trails` 2 and 7 more) |
| Called from | `PanelP1` |
| Calls | `LoadRecordP1` (tail) |

### `JpLoadRecordP2` (`$D6E4`)

**JP LoadRecordP2**

Witness: L1 2 (kb).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 2 calls (`stage1/rec/kb` 2) |
| Called from | `PanelP2` |
| Calls | `LoadRecordP2` (tail) |

### `JpSaveRecordP1` (`$D6E7`)

**JP SaveRecordP1**

Witness: L1 21 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 1 call, 10 t-states own (0.00 %) |
| Runs (the other recordings) | 20 calls (`stage1/rec/warp` 8, `stage1/rec/kb` 2, `stage1/rec/trails` 2 and 7 more) |
| Called from | `PanelP1` |
| Calls | `SaveRecordP1` (tail) |

### `JpSaveRecordP2` (`$D6EA`)

**JP SaveRecordP2**

Witness: L1 2 (kb).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 2 calls (`stage1/rec/kb` 2) |
| Called from | `PanelP2` |
| Calls | `SaveRecordP2` (tail) |

### `JpStop` (`$D6ED`)

**JP Stop**

Known only from the code: no recording runs it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `JpAccelerate` (`$D6F0`)

**JP Accelerate**

Known only from the code: no recording runs it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `JpSlowDown` (`$D6F3`)

**JP SlowDown**

Known only from the code: no recording runs it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `JpShowMaxTime` (`$D6F6`)

**JP ShowMaxTime**

Witness: L1 21 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 1 call, 10 t-states own (0.00 %) |
| Runs (the other recordings) | 20 calls (`stage1/rec/warp` 8, `stage1/rec/kb` 2, `stage1/rec/trails` 2 and 7 more) |
| Called from | `ShowHud` (tail) |
| Calls | `ShowMaxTime` (tail) |

### `JpShowClock` (`$D6F9`)

**JP ShowClock**

Witness: L1 21 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 1 call, 10 t-states own (0.00 %) |
| Runs (the other recordings) | 20 calls (`stage1/rec/warp` 8, `stage1/rec/kb` 2, `stage1/rec/trails` 2 and 7 more) |
| Called from | `ShowHud` |
| Calls | `ShowClock` (tail) |

### `JpClockTick` (`$D6FC`)

**JP ClockTick**

Known only from the code: no recording runs it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `JpShowBars` (`$D6FF`)

**JP ShowBars**

Witness: L1 23 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 1 call, 10 t-states own (0.00 %) |
| Runs (the other recordings) | 22 calls (`stage1/rec/warp` 8, `stage1/rec/kb` 4, `stage1/rec/trails` 2 and 7 more) |
| Called from | `PanelP2`, `PanelP1` |
| Calls | `ShowBars` (tail) |

### `JpNothing` (`$D702`)

**JP `$0000`**

Known only from the code: no recording runs it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `JpPlayers` (`$D705`)

**JP Players**

Known only from the code: no recording runs it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `JpPrintShadow` (`$D708`)

**JP PrintShadow**

Known only from the code: no recording runs it.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `JpSetupIm2` (`$D70B`)

**JP SetupIm2**

Witness: L1 15 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 1 call, 10 t-states own (0.00 %) |
| Runs (the other recordings) | 14 calls (`stage1/rec/menu` 3, `stage1/rec/turn` 2, `stage1/rec/empty` 1 and 8 more) |
| Called from | `MenuLoop` |
| Calls | `SetupIm2` (tail) |

### `NewGame` (`$D80D`)

**A game: trail 1, scores "00000", the riding mask from Players; each trail: select, intro, panels, then Pass until the finish or TIME OUT**

Trail = 0, SecondRound = 0, Riding = 1 or 3 (PlayerCount); LoadIntro; then for each trail SelectTrail, FrameCount = `$FF`, InitListWidths, InitRecords, TrailIntro, ShowHud, ClearKeys, EI, and the passes. TrailEnd jumps back to NextTrail (`$D82F`).

FrameCount = 0, ReadP1Controls, ReadP2Controls, ClearKeys, ClockTick, Players; then the wait loop on FrameCount (c1: 30 269 229 runs of `$D86B` over 5081 passes). Both players' Finished bits set (as Riding) end the trail (TrailEnd); the clock's first digit equal to MaxTime's: TIME OUT for both (TimeOut), then TrailEnd when someone finished, else 250 frames and the game ends. With two players a pass is often longer: 8 to 13 frames in kb (640 of 811 passes 7). The TIME OUT test (`$D89E`) compares only the hundreds digit with MaxTime's first: a limit is a multiple of 100 passes.

Witness: L1 11 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 1 call, 202,088,163 t-states own (12.91 %) |
| Runs (the other recordings) | 10 calls (`stage1/rec/fuel` 1, `stage1/rec/trail1` 1, `stage1/rec/warp` 1 and 7 more) |
| Called from | `GameEntry`, `TrailEnd` (tail) |
| Calls | `JpLoadIntro`, `JpTrailIntro`, `JpShowHud`, `JpInitListWidths`, `JpClearKeys`, `RecordFieldP1`, `RecordFieldP2`, `ReadP1Controls`, `ReadP2Controls`, `InitRecords`, `ClockTick`, `Players`, `SelectTrail`, `TrailEnd` (tail) |
| Reads | `$6947`-`$6950` (`PlayerVars`, `Scores`, `ScoreP2`); `$D6BC`-`$D6CC` (`FrameCount`, `Riding`, `Trail`, `FinishDistance` and 7 more); `$D7A5` (`Finished`); `$D8C0` (`l_D8BF+1`) |
| Writes | `$6948`-`$6951` (`Scores`, `ScoreP2`); `$8084`-`$8085` (`AttrBase`); `$8113`-`$8114` (`Controls1`, `Controls2`); `$D6BC`-`$D6BF` (`FrameCount`, `Riding`, `Trail`); `$D717`-`$D727` (`RecordP1+9`); `$D749` (`RecordP2+9`); 2 more ranges |

### `RecordFieldP1` (`$D88A`)

**A = RecordP1's field +9 (speed), Z when 0**

Witness: L1 5866 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 601 calls, 15,626 t-states own (0.00 %) |
| Runs (the other recordings) | 5,265 calls (`stage1/rec/fuel` 1,253, `stage1/rec/trails` 921, `stage1/rec/warp` 894 and 7 more) |
| Called from | `NewGame`, `RecordFieldP2` |
| Calls | `RecordFieldP2` (tail) |

### `RecordFieldP2` (`$D890`)

**A = RecordP2's field +9**

Witness: L1 3806 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 545 calls, 66,076 t-states own (0.00 %) |
| Runs (the other recordings) | 3,261 calls (`stage1/rec/fuel` 1,095, `stage1/rec/kb` 553, `stage1/rec/trail1` 548 and 7 more) |
| Called from | `NewGame`, `RecordFieldP1` (tail) |
| Calls | `RecordFieldP1`, `RecordField`, `TimeOut`, `TrailEnd` (tail) |
| Reads | `$D717` (`RecordP1+9`); `$D749` (`RecordP2+9`) |

### `Init` (`$D8C3`)

**Controls off (player 2 on the keyboard... SinclairOn = 1), DetectKempston, the row tables, the text widths, FrameCount = `$FF`**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 1 call, 204 t-states own (0.00 %) |
| Called from | `GameEntry` |
| Calls | `JpInitTextWidths`, `JpDetectKempston`, `JpBuildRowAddrs`, `JpBuildBufferRows`, `JpClearKeys` |
| Writes | `$8086`-`$8088` (`KempstonOn`, `Keyboard1Alt`, `SinclairOn`); `$80DF`-`$80E0` (`ScreenBase`); `$D6BC` (`FrameCount`); `$D7A5` (`Finished`) |

### `SetupIm2` (`$D8ED`)

**IM 2: I = `$FE`, the table `$FE00-$FF00` all `$80`, JP Interrupt at `$8080`**

Witness: L1 26 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 2 calls, 11,024 t-states own (0.00 %) |
| Runs (the other recordings) | 24 calls (`stage1/rec/warp` 8, `stage1/rec/menu` 3, `stage1/rec/kb` 2 and 8 more) |
| Called from | `JpSetupIm2` (tail), `GameEntry`, `TrailEnd` |
| Reads | `$FE00`-`$FEFF` (`Im2Table`) |
| Writes | `$8080`-`$8082` (`RenderVars`); `$D7A4` (`BeeperByte`); `$FE00`-`$FF00` (`Im2Table`) |

### `ReadP1Controls` (`$D911`)

**Controls1 = player 1's five tests as bits (4 left, 3 right, 2 up, 1 down, 0 jump)**

Witness: L1 27315 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

[Animation: `ReadP1Controls` at work](img/routines/ReadP1Controls.gif)

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 2,918 calls, 515,062 t-states own (0.03 %) |
| Runs (the other recordings) | 24,397 calls (`stage1/rec/warp` 8,882, `stage1/rec/trail1` 5,322, `stage1/rec/kb` 3,095 and 8 more) |
| Called from | `NewGame`, `Interrupt` |
| Calls | `JpP1Left`, `JpP1Right`, `JpP1Up`, `JpP1Down`, `JpP1Jump` |
| Reads | `$8113` (`Controls1`) |
| Writes | `$8113` (`Controls1`) |

### `ReadP2Controls` (`$D942`)

**Controls2 from player 2's tests**

Witness: L1 27315 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 2,918 calls, 455,208 t-states own (0.03 %) |
| Runs (the other recordings) | 24,397 calls (`stage1/rec/warp` 8,882, `stage1/rec/trail1` 5,322, `stage1/rec/kb` 3,095 and 8 more) |
| Called from | `NewGame`, `Interrupt` |
| Calls | `JpP2Left`, `JpP2Right`, `JpP2Up`, `JpP2Down`, `JpP2Jump` |
| Reads | `$8114` (`Controls2`) |
| Writes | `$8114` (`Controls2`) |

### `RecordField` (`$D974`)

**A = (IX + DE), Z when 0**

Witness: L1 134970 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 11,681 calls, 700,898 t-states own (0.04 %) |
| Runs (the other recordings) | 123,289 calls (`stage1/rec/warp` 24,064, `stage1/rec/kb` 24,032, `stage1/rec/fuel` 23,419 and 7 more) |
| Called from | `RecordFieldP2`, `EngineOne` |
| Reads | `$D710`-`$D717` (`RecordP1+2`); `$D742`-`$D749` (`RecordP2+2`) |

### `EngineSound` (`$D97C`)

**Both players' engine tones (from Interrupt each frame in play)**

For each record with the rider mounted (+2) and a speed (+9): three bursts of a square wave whose half-period is `$1E` - speed + 1 (Tone): the pitch rises with the speed.

Witness: L1 51492 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 5,048 calls, 227,160 t-states own (0.01 %) |
| Runs (the other recordings) | 46,444 calls (`stage1/rec/fuel` 10,030, `stage1/rec/warp` 8,969, `stage1/rec/kb` 8,334 and 7 more) |
| Called from | `Interrupt`, `Update` |
| Calls | `EngineOne` (falls into) |

### `EngineOne` (`$D987`)

**One record's engine tone**

Witness: L1 102984 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 10,096 calls, 409,387 t-states own (0.03 %) |
| Runs (the other recordings) | 92,888 calls (`stage1/rec/fuel` 20,060, `stage1/rec/warp` 17,938, `stage1/rec/kb` 16,668 and 7 more) |
| Called from | `EngineSound` (falls into) |
| Calls | `RecordField`, `Tone` (falls into) |

### `Tone` (`$D99E`)

**B bursts of a tone: Click, a delay of C x 3 loops**

Witness: L1 167597 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 438 calls, 1,329,311 t-states own (0.08 %) |
| Runs (the other recordings) | 22,627 calls (`stage1/rec/warp` 6,750, `stage1/rec/kb` 5,732, `stage1/rec/trails` 5,248 and 7 more) |
| Called from | `EngineOne` (falls into), `Landing`, `CountBonus` |
| Calls | `Noise` (tail), `Click` |

### `Noise` (`$D9AF`)

**C clicks with random delays (Random): the thump of a landing**

Witness: L1 1690 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 5 calls, 82,698 t-states own (0.01 %) |
| Runs (the other recordings) | 164 calls (`stage1/rec/kb` 62, `stage1/rec/warp` 33, `stage1/rec/empty` 23 and 7 more) |
| Called from | `Tone` (tail), `Landing` |
| Calls | `JpRandom`, `Click` |
| Ports out | `$00FE` |

### `Click` (`$D9C7`)

**Toggle the speaker bit in BeeperByte and send it**

Witness: L1 169287 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 1,374 calls, 74,362 t-states own (0.00 %) |
| Runs (the other recordings) | 167,913 calls (`stage1/rec/warp` 106,992, `stage1/rec/kb` 23,367, `stage1/rec/trails` 21,405 and 7 more) |
| Called from | `Tone`, `Noise` |
| Reads | `$D7A4` (`BeeperByte`) |
| Writes | `$D7A4` (`BeeperByte`) |
| Ports out | `$00FE`, `$10FE` |

### `Interrupt` (`$D9D2`)

**The IM 2 handler: in play count FrameCount and sound the engines; in the front end read both players' controls**

Saves every register. FrameCount < `$FF`: +1, ScanKeys, EngineSound. `$FF`: Controls1 = Controls2 = 0, ScanKeys, ReadP1Controls, ReadP2Controls. c1: 58 177 interrupts. An entry costs 2 555 T with no engine running, about 5 750 T with one, about 12 600 T with two (Tone inside the interrupt); 3 585 T in the front end (handler_time over c1 15055, 15356, 14700; kb 3118).

Witness: L1 66259 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 6,766 calls, 1,796,624 t-states own (0.11 %) |
| Runs (the other recordings) | 59,493 calls (`stage1/rec/warp` 16,065, `stage1/rec/fuel` 9,174, `stage1/rec/trail1` 9,170 and 8 more) |
| Called from | `RenderVars` (tail) |
| Calls | `JpScanKeys`, `ReadP1Controls`, `ReadP2Controls`, `EngineSound` |
| Reads | `$D6BC` (`FrameCount`) |
| Writes | `$8113`-`$8114` (`Controls1`, `Controls2`); `$D6BC` (`FrameCount`) |

### `AbortKey` (`$DA01`)

**Restart the game when key 1 (KeyStates+15: row `$F7FE`, bit 0) is down: FrameCount = `$FF`, SP = `$FFDA`, JP NewGame**

No jump reaches it (the handler's two paths jump over it to `$DA14`): a debug or abort key left in. Known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `Players` (`$EC7F`)

**Each riding player's pass: PassP1, PassP2**

Witness: L1 5868 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 600 calls, 76,200 t-states own (0.00 %) |
| Runs (the other recordings) | 5,268 calls (`stage1/rec/fuel` 1,254, `stage1/rec/trails` 921, `stage1/rec/warp` 893 and 7 more) |
| Called from | `NewGame` |
| Calls | `PassP1`, `PassP2` |
| Reads | `$D6BE` (`Riding`) |
| Writes | `$8122`-`$8123` (`PlayerIndex`, `SeenCount`) |

### `SelectTrail` (`$EC9C`)

**TrailListA, TrailListB and FinishDistance from the trail's record (TrailRecords, Trail5, Trail6)**

Witness: L1 21 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 1 call, 337 t-states own (0.00 %) |
| Runs (the other recordings) | 20 calls (`stage1/rec/warp` 8, `stage1/rec/kb` 2, `stage1/rec/trails` 2 and 7 more) |
| Called from | `NewGame` |
| Calls | `JpMultiply` |
| Reads | `$60AC`-`$60B1` (system); `$7C9C`-`$7CB3` (`TrailRecords`); `$D6BF` (`Trail`); `$EE84`-`$EE89` (`Trail5`) |
| Writes | `$D6B6`-`$D6C1` (`LoopVars`, `TrailListB`, `SavedSp0`, `FrameCount` and 3 more) |

### `TrailEnd` (`$ECE0`)

**The trail's end: the finish tune, the bonus counted into the scores, the next trail; after trail 6 the second round**

Riding = Finished; the tune player back from `$5B00`; TunePlay tune 1 with no hook (no key stops it); SetupIm2; 50 frames; the finished halves' colour bands; CountBonus; 100 frames; Trail + 1, NextTrail. After trail 6, SecondRound = 1 and Trail = 0 (trails: 9 trail ends).

Witness: L1 10 (kb, trails, wallcrash, warp).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 10 calls (`stage1/rec/warp` 7, `stage1/rec/wallcrash` 1, `stage1/rec/trails` 1 and 1 more) |
| Called from | `NewGame` (tail), `RecordFieldP2` (tail) |
| Calls | `NewGame` (tail), `SetupIm2`, `CountBonus`, `BandP1`, `BandP2`, `TunePlay` |
| Reads | `$5B00`-`$60AA` (system); `$D6BF` (`Trail`); `$D7A5` (`Finished`); `$ED15` (`l_ED14+1`); `$ED37` (`l_ED36+1`) |
| Writes | `$8084`-`$8085` (`AttrBase`); `$D6BE`-`$D6BF` (`Riding`, `Trail`); `$D7A6` (`SecondRound`); `$F850`-`$FDFA` (`TunePlay0`, `TunePlay`, `TuneLoop`, `TuneInterrupt` and 33 more) |

### `CountBonus` (`$ED52`)

**Count each finished player's Bonus into the score, a point (shown as 10) and a tone at a time**

Witness: L1 3642 (kb, trails, wallcrash, warp).

[Animation: `CountBonus` at work](img/routines/CountBonus.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 3,642 calls (`stage1/rec/warp` 3,205, `stage1/rec/trails` 204, `stage1/rec/kb` 202 and 1 more) |
| Called from | `TrailEnd`, `ScoreDigit` |
| Calls | `Tone`, `BonusP1`, `BonusP2` |

### `BonusP1` (`$ED6A`)

**Player 1's next bonus point**

Witness: L1 3642 (kb, trails, wallcrash, warp).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 3,642 calls (`stage1/rec/warp` 3,205, `stage1/rec/trails` 204, `stage1/rec/kb` 202 and 1 more) |
| Called from | `CountBonus` |
| Calls | `LoadRecordP1`, `SaveRecordP1`, `BonusDec`, `ScoreUpP1` (tail) |
| Reads | `$D7A5` (`Finished`) |

### `BonusP2` (`$ED82`)

**Player 2's**

Witness: L1 3642 (kb, trails, wallcrash, warp).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 3,642 calls (`stage1/rec/warp` 3,205, `stage1/rec/trails` 204, `stage1/rec/kb` 202 and 1 more) |
| Called from | `CountBonus` |
| Calls | `LoadRecordP2`, `SaveRecordP2`, `BonusDec`, `ScoreUpP2` (tail) |
| Reads | `$D7A5` (`Finished`) |

### `BonusDec` (`$ED9A`)

**Bonus - 1; Z when it was 0**

Witness: L1 3844 (kb, trails, wallcrash, warp).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 3,844 calls (`stage1/rec/warp` 3,205, `stage1/rec/kb` 404, `stage1/rec/trails` 204 and 1 more) |
| Called from | `BonusP1`, `BonusP2` |
| Reads | `$D79B`-`$D79C` (`Bonus`) |
| Writes | `$D79B`-`$D79C` (`Bonus`) |

### `BandP1` (`$EDA7`)

**Colour player 1's band**

Witness: L1 10 (kb, trails, wallcrash, warp).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 10 calls (`stage1/rec/warp` 7, `stage1/rec/kb` 1, `stage1/rec/trails` 1 and 1 more) |
| Called from | `TrailEnd` |
| Calls | `JpFillAttrs` (tail) |

### `BandP2` (`$EDB1`)

**Colour player 2's band**

Witness: L1 1 (kb).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 1 call (`stage1/rec/kb` 1) |
| Called from | `TrailEnd` |
| Calls | `JpFillAttrs` (tail) |

## vehicle

`src/game/vehicle.asm`

### `EngineTimer` (`$DA1E`)

**Step the engine note's timer: at speed, every 1 or 2 passes (speed under 3) flip the tone bit**

Witness: L1 6681 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 600 calls, 26,931 t-states own (0.00 %) |
| Runs (the other recordings) | 6,081 calls (`stage1/rec/kb` 1,626, `stage1/rec/fuel` 1,254, `stage1/rec/trails` 921 and 7 more) |
| Called from | `PassP1`, `PassP2` |
| Reads | `$D77B` (`Speed`); `$D79A` (`EngineNote`) |
| Writes | `$D79A` (`EngineNote`) |

### `PassP1` (`$DA4F`)

**Player 1's pass: the top half (BufferP1 to `$4021`), the record in, the update, the copy, the record out**

ScreenBase `$4021`, BufferBase `$F03C`, AttrBase `$5821`, ClearBufferP1, HudY `$BE`, LoadRecordP1, SlowDown when finished, PassControls = Controls1, EngineTimer, Update, ClearKeys, Advance, CopyBufferP1, FlushAttrs, SaveRecordP1 (c1: 5081 passes).

Witness: L1 5868 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 600 calls, 180,000 t-states own (0.01 %) |
| Runs (the other recordings) | 5,268 calls (`stage1/rec/fuel` 1,254, `stage1/rec/trails` 921, `stage1/rec/warp` 893 and 7 more) |
| Called from | `Players` |
| Calls | `JpClearKeys`, `JpCopyBufferP1`, `JpClearBufferP1`, `JpFlushAttrs`, `EngineTimer`, `Update`, `Advance`, `LoadRecordP1`, `SaveRecordP1` (tail), `SlowDown` |
| Reads | `$8113` (`Controls1`); `$D7A5` (`Finished`) |
| Writes | `$8084`-`$8085` (`AttrBase`); `$80DF`-`$80E0` (`ScreenBase`); `$8144`-`$8145` (`BufferBase`); `$D6C2`-`$D6C3` (`HudY`, `PassControls`) |

### `PassP2` (`$DA8F`)

**Player 2's pass: the bottom half (BufferP2 to `$48A1`)**

Witness: L1 813 (kb).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 813 calls (`stage1/rec/kb` 813) |
| Called from | `Players` |
| Calls | `JpCopyBufferP2`, `JpClearBufferP2`, `JpFlushAttrs`, `EngineTimer`, `Update`, `Advance`, `LoadRecordP2`, `SaveRecordP2` (tail), `SlowDown` |
| Reads | `$8114` (`Controls2`); `$D7A5` (`Finished`) |
| Writes | `$8084`-`$8085` (`AttrBase`); `$80DF`-`$80E0` (`ScreenBase`); `$8144`-`$8145` (`BufferBase`); `$D6C2`-`$D6C3` (`HudY`, `PassControls`) |

### `Update` (`$DACC`)

**A player's update: draw list A, the ATV's physics, the controls, the jump, the rider, the tumble, list B, the deferred sprites and the ATV, the finish**

Clears the deferred lists; WalkList over list A at Distance; EngineSound; AtvPhysics; Controls; unless riderless: JumpControl, RiderUpdate, Tumble; WalkList over list B at Scenery; FlushDeferredB, DrawAtvAndRider, FlushDeferredA; then the finish test (FinishCheck).

Bonus = ((MaxTime - the clock) / 2 + 1) x (Trail + 1) + 1, the clock read as a number (DigitsValue). trail1: the finish at frame (see NOTES).

Witness: L1 6681 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

[Animation: `Update` at work](img/routines/Update.gif)

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 600 calls, 352,257 t-states own (0.02 %) |
| Runs (the other recordings) | 6,081 calls (`stage1/rec/kb` 1,626, `stage1/rec/fuel` 1,254, `stage1/rec/trails` 921 and 7 more) |
| Called from | `PassP1`, `PassP2` |
| Calls | `JpMultiply`, `JpFlushDeferredA`, `JpFlushDeferredB`, `JpWalkList`, `EngineSound`, `DigitsValue`, `DrawAtvAndRider`, `RiderUpdate`, `Controls`, `JumpControl`, `AtvPhysics`, `Tumble`, `PrintShadow` (tail) |
| Reads | `$8122` (`PlayerIndex`); `$D6B6`-`$D6CB` (`LoopVars`, `TrailListB`, `SavedSp0`, `FrameCount` and 9 more); `$D775` (`AtvFrame`); `$D788`-`$D7A5` (`RiderSavedHeight`, `BeeperByte`) |
| Writes | `$80DB`-`$80DD` (`SpriteX`, `SpriteY`); `$811B`-`$8120` (`ListBase`, `ListIndexPtr`, `ListScroll`); `$8146`-`$8148` (`DeferredA`); `$81E9`-`$81EB` (`DeferredB`); `$828C`-`$828E` (`DeferredAttrs`); `$D786` (`RiderHeight`); 2 more ranges |

### `RiderUpdate` (`$DE38`)

**The rider each pass: on foot (RiderOnFoot, RiderGround) or mounted (RiderMounted)**

Witness: L1 6676 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 600 calls, 79,746 t-states own (0.01 %) |
| Runs (the other recordings) | 6,076 calls (`stage1/rec/kb` 1,626, `stage1/rec/fuel` 1,254, `stage1/rec/trails` 921 and 7 more) |
| Called from | `Update` |
| Calls | `RiderPose`, `RiderOnFoot`, `RiderGroundMounted`, `RiderGround` (tail), `FallRider` (tail), `Thrown` (tail) |
| Reads | `$D774` (`Mounted`); `$D786` (`RiderHeight`); `$D798`-`$D7A0` (`FallPhase`, `ThrowSpeed`, `EngineNote`, `Bonus` and 2 more) |

### `RiderPose` (`$DE7A`)

**The mounted rider's pose from the ATV's frame (RidePoses)**

Witness: L1 2325 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 55 calls, 13,136 t-states own (0.00 %) |
| Runs (the other recordings) | 2,270 calls (`stage1/rec/trails` 631, `stage1/rec/kb` 504, `stage1/rec/warp` 436 and 7 more) |
| Called from | `RiderUpdate` |
| Calls | `RiderPoseY` |
| Reads | `$D775`-`$D784` (`AtvFrame`, `Facing`, `AtvX`, `AtvHeight` and 10 more); `$DEF0`-`$DF16` (`RidePoses+4`) |
| Writes | `$D783`-`$D785` (`RiderFrame`, `RiderFacing`, `RiderX`) |

### `RiderPoseY` (`$DF18`)

**The rider's height on the ATV**

Witness: L1 2325 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 55 calls, 6,147 t-states own (0.00 %) |
| Runs (the other recordings) | 2,270 calls (`stage1/rec/trails` 631, `stage1/rec/kb` 504, `stage1/rec/warp` 436 and 7 more) |
| Called from | `RiderPose` |
| Reads | `$D786` (`RiderHeight`) |
| Writes | `$D786`-`$D788` (`RiderHeight`, `RiderSavedX`, `RiderSavedHeight`) |

### `RiderOnFoot` (`$DF37`)

**The rider walks against a step: back to his last x; jumps or falls to the ground**

Witness: L1 4057 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

[Animation: `RiderOnFoot` at work](img/routines/RiderOnFoot.gif)

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 523 calls, 45,483 t-states own (0.00 %) |
| Runs (the other recordings) | 3,534 calls (`stage1/rec/kb` 1,076, `stage1/rec/fuel` 1,070, `stage1/rec/trail1` 537 and 7 more) |
| Called from | `RiderUpdate`, `RiderJumpStart` (tail) |
| Reads | `$D772` (`Record`); `$D786`-`$D787` (`RiderHeight`, `RiderSavedX`); `$D7A0` (`GroundBelowRider`) |
| Writes | `$D772`-`$D786` (`Record`, `VSpeed`, `Mounted`, `AtvFrame` and 15 more) |

### `UseFuel` (`$DF91`)

**Fuel - speed x 2; the FUEL bar shrinks by a nibble each `$400`; under `$400` OutOfFuel**

fuel: the bar from `$B0` down to `$90` in 8 steps. Recording empty (the fuel's high byte POKEd to 5 at frame 567) runs out at frame 732 (OutOfFuel first, the text from 736): OutOfFuel ran 83 times, "OUT OF FUEL" is printed, the two SlowDowns a moving pass leave the ATV crawling forward while the throttle is held (screens 000939-after to 002269-end); only the clock ends the run. The first cell goes at the first moving pass (`$2000` less anything has level `$1C`): the usable tank is `$1C00`.

Witness: L1 1875 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

[Animation: `UseFuel` at work](img/routines/UseFuel.gif)

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 58 calls, 13,666 t-states own (0.00 %) |
| Runs (the other recordings) | 1,817 calls (`stage1/rec/kb` 520, `stage1/rec/warp` 439, `stage1/rec/trails` 257 and 7 more) |
| Called from | `Advance` |
| Calls | `FuelBarStep` (tail) |
| Reads | `$4112`-`$4515` (screen); `$4612`-`$4615` (screen); `$51F2`-`$51F5` (screen); `$52F2`-`$52F5` (screen); `$53F2`-`$53F5` (screen); `$54F2`-`$54F5` (screen); 5 more ranges |
| Writes | `$4112`-`$4515` (screen); `$4612`-`$4615` (screen); `$51F2`-`$51F5` (screen); `$52F2`-`$52F5` (screen); `$53F2`-`$53F5` (screen); `$54F2`-`$54F5` (screen); 4 more ranges |

### `FuelBarStep` (`$DFCD`)

**clear the bar's last 4 pixels (6 lines)**

Witness: L1 146 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 2 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 84 calls (`stage1/rec/empty` 84) |
| Called from | `UseFuel` (tail) |
| Calls | `GfxTable`, `SlowDown`, `PrintShadow` (tail) |
| Reads | `$4112` (screen); `$4212` (screen); `$4312` (screen); `$4412` (screen); `$4512` (screen); `$4612` (screen); 3 more ranges |
| Writes | `$4112` (screen); `$4212` (screen); `$4312` (screen); `$4412` (screen); `$4512` (screen); `$4612` (screen); 2 more ranges |

### `Advance` (`$E011`)

**Move along the trail by the speed in the facing direction, use fuel**

Speed under 2: no move. Forwards: Distance + speed x 128, Scenery + speed x 32 (ForwardList, ForwardScenery); backwards the same down. Each `$1000` of Distance crossed scores a point up forwards, down backwards (ScoreStep).

Witness: L1 6700 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 608 calls, 22,893 t-states own (0.00 %) |
| Runs (the other recordings) | 6,092 calls (`stage1/rec/kb` 1,628, `stage1/rec/fuel` 1,257, `stage1/rec/trails` 921 and 7 more) |
| Called from | `PassP1`, `PassP2`, `Crash` |
| Calls | `UseFuel`, `BackList`, `BackScenery` (tail), `ForwardList`, `ForwardScenery` (tail) |
| Reads | `$D776`-`$D77B` (`Facing`, `AtvX`, `AtvHeight`, `PrevHeight` and 1 more) |

### `BackList` (`$E030`)

**Distance - speed x 128; at 0 the trail's start: stop**

Witness: L1 55 (c1, fuel, kb, speedcrash, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 3 calls, 489 t-states own (0.00 %) |
| Runs (the other recordings) | 52 calls (`stage1/rec/turn` 39, `stage1/rec/warp` 4, `stage1/rec/fuel` 3 and 5 more) |
| Called from | `Advance` |
| Calls | `ScoreDown` |
| Reads | `$D77B`-`$D78B` (`Speed`, `Fuel`, `SpeedBarLen`, `FuelBar` and 11 more) |
| Writes | `$D789`-`$D78B` (`Distance`, `TrackPos`) |

### `ScoreDown` (`$E072`)

**One point off the current player's score**

Witness: L1 26 (fuel, kb, speedcrash, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 26 calls (`stage1/rec/turn` 17, `stage1/rec/warp` 3, `stage1/rec/kb` 2 and 3 more) |
| Called from | `BackList` |
| Calls | `ScoreDownP1` (tail), `ScoreDownP2` (tail) |
| Reads | `$8122` (`PlayerIndex`) |

### `BackScenery` (`$E07D`)

**Scenery - speed x 32**

Witness: L1 55 (c1, fuel, kb, speedcrash, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 3 calls, 402 t-states own (0.00 %) |
| Runs (the other recordings) | 52 calls (`stage1/rec/turn` 39, `stage1/rec/warp` 4, `stage1/rec/fuel` 3 and 5 more) |
| Called from | `Advance` (tail) |
| Reads | `$D77B` (`Speed`); `$D78E`-`$D78F` (`Scenery`, `SceneryPos`) |
| Writes | `$D78E`-`$D78F` (`Scenery`, `SceneryPos`) |

### `ForwardList` (`$E0A3`)

**Distance + speed x 128**

Witness: L1 1820 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 55 calls, 8,723 t-states own (0.00 %) |
| Runs (the other recordings) | 1,765 calls (`stage1/rec/kb` 518, `stage1/rec/warp` 435, `stage1/rec/trails` 256 and 7 more) |
| Called from | `Advance` |
| Calls | `ScoreStep` |
| Reads | `$D77B`-`$D78B` (`Speed`, `Fuel`, `SpeedBarLen`, `FuelBar` and 11 more) |
| Writes | `$D789`-`$D78B` (`Distance`, `TrackPos`) |

### `ScoreStep` (`$E0CB`)

**One point onto the current player's score (not after the finish): +1, shown as +10**

Witness: L1 811 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 23 calls, 1,748 t-states own (0.00 %) |
| Runs (the other recordings) | 788 calls (`stage1/rec/kb` 260, `stage1/rec/warp` 170, `stage1/rec/trails` 145 and 7 more) |
| Called from | `ForwardList` |
| Calls | `ScoreUpP1` (tail), `ScoreUpP2` (tail) |
| Reads | `$8122` (`PlayerIndex`); `$D7A5` (`Finished`) |

### `ForwardScenery` (`$E0E1`)

**Scenery + speed x 32 (Speed x 256 shifted right three times): a quarter of ForwardList's speed x 128**

Witness: L1 1820 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 55 calls, 6,930 t-states own (0.00 %) |
| Runs (the other recordings) | 1,765 calls (`stage1/rec/kb` 518, `stage1/rec/warp` 435, `stage1/rec/trails` 256 and 7 more) |
| Called from | `Advance` (tail) |
| Reads | `$D77B` (`Speed`); `$D78E`-`$D790` (`Scenery`, `SceneryPos`) |
| Writes | `$D78E`-`$D790` (`Scenery`, `SceneryPos`) |

### `Controls` (`$E105`)

**The controls, unless the rider is falling or thrown: Left, Right, Up, MountCheck**

Witness: L1 6680 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 600 calls, 77,833 t-states own (0.00 %) |
| Runs (the other recordings) | 6,080 calls (`stage1/rec/kb` 1,626, `stage1/rec/fuel` 1,254, `stage1/rec/trails` 921 and 7 more) |
| Called from | `Update` |
| Calls | `ControlLeft`, `ControlRight`, `ControlUp`, `MountCheck` |
| Reads | `$D798`-`$D799` (`FallPhase`, `ThrowSpeed`) |

### `ControlLeft` (`$E120`)

**Left: riding, throttle facing left or brake facing right (a standstill turns round); on foot, walk left**

Witness: L1 6387 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 578 calls, 78,456 t-states own (0.01 %) |
| Runs (the other recordings) | 5,809 calls (`stage1/rec/kb` 1,580, `stage1/rec/fuel` 1,196, `stage1/rec/trails` 903 and 7 more) |
| Called from | `Controls` |
| Calls | `SlowDown` (tail), `Accelerate` (tail), `OnGround` |
| Reads | `$D6C3` (`PassControls`); `$D772`-`$D785` (`Record`, `VSpeed`, `Mounted`, `AtvFrame` and 14 more) |
| Writes | `$D775`-`$D785` (`AtvFrame`, `Facing`, `AtvX`, `AtvHeight` and 11 more) |

### `ControlRight` (`$E1F0`)

**Right: the same the other way**

Witness: L1 6387 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

[Animation: `ControlRight` at work](img/routines/ControlRight.gif)

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 578 calls, 148,576 t-states own (0.01 %) |
| Runs (the other recordings) | 5,809 calls (`stage1/rec/kb` 1,580, `stage1/rec/fuel` 1,196, `stage1/rec/trails` 903 and 7 more) |
| Called from | `Controls` |
| Calls | `SlowDown` (tail), `Accelerate` (tail), `OnGround` |
| Reads | `$D6C3` (`PassControls`); `$D772`-`$D785` (`Record`, `VSpeed`, `Mounted`, `AtvFrame` and 14 more) |
| Writes | `$D775`-`$D785` (`AtvFrame`, `Facing`, `AtvX`, `AtvHeight` and 11 more) |

### `ControlUp` (`$E2BC`)

**Up: WheelieTimer = 10 and the nose up; at full nose-up (`$44`) the rider is thrown off backwards (ThrowOff: recording throwoff, frames 612-619)**

Witness: L1 6387 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 578 calls, 37,247 t-states own (0.00 %) |
| Runs (the other recordings) | 5,809 calls (`stage1/rec/kb` 1,580, `stage1/rec/fuel` 1,196, `stage1/rec/trails` 903 and 7 more) |
| Called from | `Controls` |
| Calls | `RiderHeightClamp` (tail), `WheelieUp` (tail) |
| Reads | `$D6C3` (`PassControls`); `$D774`-`$D795` (`Mounted`, `AtvFrame`, `Facing`, `AtvX` and 22 more) |
| Writes | `$D774` (`Mounted`); `$D785`-`$D798` (`RiderX`, `RiderHeight`, `RiderSavedX`, `RiderSavedHeight` and 9 more) |

### `GetUp` (`$E31F`)

**Lying after a throw: Jump stands the rider up (on foot)**

Witness: L1 294 (c1, fuel, kb, speedcrash, throwoff, trail1, trails, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 22 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 272 runs of its first instruction, entered by a jump (`stage1/rec/fuel` 58, `stage1/rec/warp` 56, `stage1/rec/kb` 46 and 5 more) |

### `JumpControl` (`$E34B`)

**Jump: riding on the ground, a jump (VSpeed `$FD` less the climb); on foot the rider's jump**

Witness: L1 6676 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

[Animation: `JumpControl` at work](img/routines/JumpControl.gif)

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 600 calls, 169,383 t-states own (0.01 %) |
| Runs (the other recordings) | 6,076 calls (`stage1/rec/kb` 1,626, `stage1/rec/fuel` 1,254, `stage1/rec/trails` 921 and 7 more) |
| Called from | `Update` |
| Calls | `SlowDown` (tail), `WheelieUp` |
| Reads | `$D6C3` (`PassControls`); `$D772`-`$D786` (`Record`, `VSpeed`, `Mounted`, `AtvFrame` and 15 more); `$D798`-`$D7A0` (`FallPhase`, `ThrowSpeed`, `EngineNote`, `Bonus` and 2 more); `$E315`-`$E318` (`RiderJumpTable+3`) |
| Writes | `$D772`-`$D795` (`Record`, `VSpeed`, `Mounted`, `AtvFrame` and 24 more) |

### `DismountUnused` (`$E3BB`)

**A dismount no jump reaches: on foot at the ATV's height + 3**

Known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `RiderHeightClamp` (`$E3D1`)

**RiderHeight = A, at most `$4F`**

Known only from the code: no recording runs it.

Witness: L1 1 (throwoff).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 1 call (`stage1/rec/throwoff` 1) |
| Called from | `ControlUp` (tail) |
| Writes | `$D786` (`RiderHeight`) |

### `RiderJumpStart` (`$E3DD`)

**The rider's jump on foot**

Witness: L1 216 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 56 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1) |
| Runs (the other recordings) | 160 runs of its first instruction, entered by a jump (`stage1/rec/kb` 114, `stage1/rec/warp` 18, `stage1/rec/trails` 9 and 7 more) |
| Calls | `RiderOnFoot` (tail) |

### `MountCheck` (`$E46E`)

**The rider lands on the ATV: within its x range and height, facing its way, falling, the ATV upright: mount**

Rider x in AtvX-12..AtvX+18 (8 less facing left), height AtvHeight+4..+25, RiderFacing = Facing, RiderJump >= 5, AtvFrame `$38-$4D`: Mounted = 1, RiderFrame `$59` (c1: 20 mounts).

Witness: L1 6387 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

[Animation: `MountCheck` at work](img/routines/MountCheck.gif)

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 578 calls, 75,060 t-states own (0.00 %) |
| Runs (the other recordings) | 5,809 calls (`stage1/rec/kb` 1,580, `stage1/rec/fuel` 1,196, `stage1/rec/trails` 903 and 7 more) |
| Called from | `Controls` |
| Reads | `$D772`-`$D786` (`Record`, `VSpeed`, `Mounted`, `AtvFrame` and 15 more) |
| Writes | `$D772`-`$D783` (`Record`, `VSpeed`, `Mounted`, `AtvFrame` and 12 more) |

### `InitRecords` (`$E4CA`)

**Both players' records from RecordTemplate**

Witness: L1 21 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 1 call, 2,160 t-states own (0.00 %) |
| Runs (the other recordings) | 20 calls (`stage1/rec/warp` 8, `stage1/rec/kb` 2, `stage1/rec/trails` 2 and 7 more) |
| Called from | `NewGame` |
| Reads | `$D7A7`-`$D7D8` (`RecordTemplate`, `GameEntry`) |
| Writes | `$D70E`-`$D771` (`RecordP1`, `RecordP2`) |

### `LoadRecordP1` (`$E4E1`)

**Record = RecordP1**

Witness: L1 9531 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 601 calls, 652,085 t-states own (0.04 %) |
| Runs (the other recordings) | 8,930 calls (`stage1/rec/warp` 4,106, `stage1/rec/fuel` 1,255, `stage1/rec/trails` 1,127 and 7 more) |
| Called from | `JpLoadRecordP1` (tail), `PassP1`, `BonusP1` |
| Reads | `$D70E`-`$D73F` (`RecordP1`) |
| Writes | `$D772`-`$D7A3` (`Record`, `VSpeed`, `Mounted`, `AtvFrame` and 31 more) |

### `SaveRecordP1` (`$E4ED`)

**RecordP1 = Record**

Witness: L1 9519 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 601 calls, 652,104 t-states own (0.04 %) |
| Runs (the other recordings) | 8,918 calls (`stage1/rec/warp` 4,099, `stage1/rec/fuel` 1,255, `stage1/rec/trails` 1,125 and 7 more) |
| Called from | `JpSaveRecordP1` (tail), `PassP1` (tail), `BonusP1` |
| Reads | `$D772`-`$D7A3` (`Record`, `VSpeed`, `Mounted`, `AtvFrame` and 31 more) |
| Writes | `$D70E`-`$D73F` (`RecordP1`) |

### `LoadRecordP2` (`$E4F9`)

**Record = RecordP2**

Witness: L1 1017 (kb).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 1,017 calls (`stage1/rec/kb` 1,017) |
| Called from | `JpLoadRecordP2` (tail), `PassP2`, `BonusP2` |
| Reads | `$D740`-`$D771` (`RecordP2`) |
| Writes | `$D772`-`$D7A3` (`Record`, `VSpeed`, `Mounted`, `AtvFrame` and 31 more) |

### `SaveRecordP2` (`$E505`)

**RecordP2 = Record**

Witness: L1 1016 (kb).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 1,016 calls (`stage1/rec/kb` 1,016) |
| Called from | `JpSaveRecordP2` (tail), `PassP2` (tail), `BonusP2` |
| Reads | `$D772`-`$D7A3` (`Record`, `VSpeed`, `Mounted`, `AtvFrame` and 31 more) |
| Writes | `$D740`-`$D771` (`RecordP2`) |

### `Stop` (`$E511`)

**Speed 0 and the SPEED bar cleared**

Witness: L1 18 (c1, fuel, kb, speedcrash, trail1, trails, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 7 calls, 2,149 t-states own (0.00 %) |
| Runs (the other recordings) | 11 calls (`stage1/rec/fuel` 3, `stage1/rec/kb` 2, `stage1/rec/warp` 2 and 4 more) |
| Called from | `Tumble` (tail), `Crash` |
| Calls | `BarNibble` |
| Reads | `$80DB` (`SpriteX`); `$D6C2` (`HudY`); `$D77B` (`Speed`) |
| Writes | `$80DB`-`$80E0` (`SpriteX`, `SpriteY`, `ScreenBase`); `$D77B` (`Speed`) |

### `SlowDown` (`$E53E`)

**Speed - 2 (not under 0), the bar**

Witness: L1 1695 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 68 calls, 3,703 t-states own (0.00 %) |
| Runs (the other recordings) | 1,627 calls (`stage1/rec/trails` 474, `stage1/rec/warp` 279, `stage1/rec/kb` 244 and 7 more) |
| Called from | `PassP1`, `PassP2`, `FuelBarStep`, `ControlLeft` (tail), `ControlRight` (tail), `JumpControl` (tail), `Landing` (tail), `Tumble`, `Crash`, `FallRider` |
| Calls | `SpeedBar` (tail) |
| Reads | `$D77B` (`Speed`) |
| Writes | `$D77B` (`Speed`) |

### `Accelerate` (`$E54C`)

**Speed + 1, at most 21, the bar**

Witness: L1 2005 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 43 calls, 2,684 t-states own (0.00 %) |
| Runs (the other recordings) | 1,962 calls (`stage1/rec/trails` 596, `stage1/rec/kb` 404, `stage1/rec/warp` 386 and 7 more) |
| Called from | `ControlLeft` (tail), `ControlRight` (tail) |
| Calls | `SpeedBar` (falls into) |
| Reads | `$D77B` (`Speed`) |
| Writes | `$D77B` (`Speed`) |

### `SpeedBar` (`$E55D`)

**Draw the SPEED bar to the speed**

Witness: L1 3700 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 111 calls, 31,525 t-states own (0.00 %) |
| Runs (the other recordings) | 3,589 calls (`stage1/rec/trails` 1,070, `stage1/rec/warp` 665, `stage1/rec/kb` 648 and 7 more) |
| Called from | `SlowDown` (tail), `Accelerate` (falls into) |
| Calls | `GfxTable`, `BarNibble` (tail) |
| Reads | `$4108`-`$460D` (screen); `$51E8`-`$51ED` (screen); `$52E8`-`$52ED` (screen); `$53E8`-`$53ED` (screen); `$54E8`-`$54ED` (screen); `$55E8`-`$55ED` (screen); 4 more ranges |
| Writes | `$4108`-`$450D` (screen); `$4608`-`$460D` (screen); `$51E8`-`$51ED` (screen); `$52E8`-`$52ED` (screen); `$53E8`-`$53ED` (screen); `$54E8`-`$54ED` (screen); 4 more ranges |

### `BarNibble` (`$E5A1`)

**A bar's 4-pixel step (6 lines)**

Witness: L1 2409 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 83 calls, 26,891 t-states own (0.00 %) |
| Runs (the other recordings) | 1,781 calls (`stage1/rec/trails` 863, `stage1/rec/warp` 316, `stage1/rec/kb` 258 and 4 more) |
| Called from | `Stop`, `SpeedBar` (tail) |
| Calls | `GfxTable` |
| Reads | `$4108`-`$460D` (screen); `$51E8`-`$51ED` (screen); `$52E8`-`$52ED` (screen); `$53E8`-`$53ED` (screen); `$54E8`-`$54ED` (screen); `$55E8`-`$55ED` (screen); 2 more ranges |
| Writes | `$4108`-`$450D` (screen); `$4608`-`$460D` (screen); `$51E8`-`$51ED` (screen); `$52E8`-`$52ED` (screen); `$53E8`-`$53ED` (screen); `$54E8`-`$54ED` (screen); 2 more ranges |

### `Rise` (`$E5BA`)

**Rising: VSpeed + 1 towards 0, the height up by FallSteps**

Witness: L1 6676 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 600 calls, 21,569 t-states own (0.00 %) |
| Runs (the other recordings) | 6,076 calls (`stage1/rec/kb` 1,626, `stage1/rec/fuel` 1,254, `stage1/rec/trails` 921 and 7 more) |
| Called from | `AtvPhysics` |
| Reads | `$D773`-`$D778` (`VSpeed`, `Mounted`, `AtvFrame`, `Facing` and 2 more); `$E319`-`$E31D` (`FallSteps`) |
| Writes | `$D773`-`$D778` (`VSpeed`, `Mounted`, `AtvFrame`, `Facing` and 2 more) |

### `Fall` (`$E5E9`)

**Falling: VSpeed + 1 up to 5, the height down by FallSteps**

Witness: L1 510 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 32 calls, 2,980 t-states own (0.00 %) |
| Runs (the other recordings) | 478 calls (`stage1/rec/kb` 160, `stage1/rec/warp` 98, `stage1/rec/trails` 63 and 7 more) |
| Called from | `AtvPhysics` (tail) |
| Calls | `AtvPhysics` |
| Reads | `$D773`-`$D778` (`VSpeed`, `Mounted`, `AtvFrame`, `Facing` and 2 more); `$D797` (`TumbleCount`); `$E319`-`$E31D` (`FallSteps`) |
| Writes | `$D773`-`$D778` (`VSpeed`, `Mounted`, `AtvFrame`, `Facing` and 2 more) |

### `RearX` (`$E631`)

**SpriteX = the rear wheel's x**

Witness: L1 6676 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 600 calls, 38,400 t-states own (0.00 %) |
| Runs (the other recordings) | 6,076 calls (`stage1/rec/kb` 1,626, `stage1/rec/fuel` 1,254, `stage1/rec/trails` 921 and 7 more) |
| Called from | `AtvPhysics` |
| Reads | `$D776`-`$D777` (`Facing`, `AtvX`) |
| Writes | `$80DB` (`SpriteX`) |

### `FrontX` (`$E64A`)

**SpriteX = the front wheel's x (B the frame's offset)**

Witness: L1 6676 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 600 calls, 40,800 t-states own (0.00 %) |
| Runs (the other recordings) | 6,076 calls (`stage1/rec/kb` 1,626, `stage1/rec/fuel` 1,254, `stage1/rec/trails` 921 and 7 more) |
| Called from | `AtvPhysics` |
| Reads | `$D776`-`$D777` (`Facing`, `AtvX`) |
| Writes | `$80DB` (`SpriteX`) |

### `FrontXLeft` (`$E65F`)

**The left-facing tail of FrontX: LD (SpriteX),A; RET (run when the ATV faces left: recording turn)**

Witness: L1 43 (turn).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 43 runs of its first instruction, entered by a jump (`stage1/rec/turn` 43) |

### `Landing` (`$E663`)

**The thump of a landing: a tone and a noise, SlowDown**

Witness: L1 169 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

[Animation: `Landing` at work](img/routines/Landing.gif)

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 5 calls, 410 t-states own (0.00 %) |
| Runs (the other recordings) | 164 calls (`stage1/rec/kb` 62, `stage1/rec/warp` 33, `stage1/rec/empty` 23 and 7 more) |
| Called from | `AtvPhysics` |
| Calls | `Tone`, `Noise`, `SlowDown` (tail) |
| Writes | `$D773` (`VSpeed`) |

### `AtvPhysics` (`$E676`)

**The ATV each pass: rise or fall, the ground under the wheels, landing, the slope, crash tests**

Not riderless. Rise; GroundUnder at the rear and the front wheel (GroundY the higher); above the ground Fall, else land (Landing when VSpeed was nonzero); a drop of 7 or more after a climb: Crash. Then the nose: the ground under the nose against the wheels gives the frame by SlopeFrames; a step of `$15` or more: Crash; WheelieDown when the timer ran out or Down is held.

Witness: L1 6680 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

[Animation: `AtvPhysics` at work](img/routines/AtvPhysics.gif)

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 600 calls, 439,267 t-states own (0.03 %) |
| Runs (the other recordings) | 6,080 calls (`stage1/rec/kb` 1,626, `stage1/rec/fuel` 1,254, `stage1/rec/trails` 921 and 7 more) |
| Called from | `Update`, `Fall` |
| Calls | `JpBufferAddr`, `Rise`, `Fall` (tail), `RearX`, `FrontX`, `Landing`, `NoseHigh` (tail), `CrashIfAir`, `GroundUnder`, `GroundScan`, `WheelieDown` (tail), `Crash` (tail) |
| Reads | `$80DB` (`SpriteX`); `$D6C3`-`$D6C8` (`PassControls`, `GroundY`); `$D773`-`$D77A` (`VSpeed`, `Mounted`, `AtvFrame`, `Facing` and 3 more); `$D795` (`WheelieTimer`); `$E61B`-`$E630` (`WheelOffsets`); `$E660`-`$E66B` (`FrontXLeft+1`, `Landing`); 1 more ranges |
| Writes | `$80DB`-`$80DD` (`SpriteX`, `SpriteY`); `$D6C4`-`$D6C8` (`GroundY`); `$D773`-`$D77A` (`VSpeed`, `Mounted`, `AtvFrame`, `Facing` and 3 more) |

### `FastFall` (`$E7BB`)

**Carry when falling at 5 lines a pass**

Witness: L1 60 (c1, fuel, kb, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 7 calls, 322 t-states own (0.00 %) |
| Runs (the other recordings) | 53 calls (`stage1/rec/fuel` 12, `stage1/rec/warp` 12, `stage1/rec/kb` 10 and 4 more) |
| Called from | `NoseHigh` |
| Reads | `$D773` (`VSpeed`) |

### `NoseHigh` (`$E7C5`)

**The nose in the air: lift the frame**

Witness: L1 72 (c1, fuel, kb, speedcrash, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 7 calls, 476 t-states own (0.00 %) |
| Runs (the other recordings) | 63 calls (`stage1/rec/fuel` 13, `stage1/rec/warp` 12, `stage1/rec/trails` 11 and 4 more) |
| Called from | `AtvPhysics` (tail) |
| Calls | `FastFall`, `CrashIfAir` |
| Reads | `$D775`-`$D778` (`AtvFrame`, `Facing`, `AtvX`, `AtvHeight`); `$E7AC`-`$E7E6` (`SlopeFrames+21`, `FastFall`, `NoseHigh`) |
| Writes | `$D775` (`AtvFrame`) |

### `OnGround` (`$E7FB`)

**Carry when the ATV is within 4 lines of the ground**

Witness: L1 1928 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 84 calls, 4,284 t-states own (0.00 %) |
| Runs (the other recordings) | 1,844 calls (`stage1/rec/kb` 540, `stage1/rec/warp` 442, `stage1/rec/trails` 268 and 7 more) |
| Called from | `ControlLeft`, `ControlRight`, `CrashIfAir`, `Tumble` |
| Reads | `$D6C4` (`GroundY`); `$D778` (`AtvHeight`) |

### `CrashIfAir` (`$E806`)

**Crash unless on the ground**

Witness: L1 9 (c1, trails).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 8 calls, 400 t-states own (0.00 %) |
| Runs (the other recordings) | 1 call (`stage1/rec/trails` 1) |
| Called from | `AtvPhysics`, `NoseHigh` |
| Calls | `OnGround`, `Crash` (tail) |

### `GroundUnder` (`$E810`)

**B = the height of the first ground pixel under SpriteX (a column scan of the buffer from the ATV's height + 8 down)**

Witness: L1 13352 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 1,200 calls, 82,800 t-states own (0.01 %) |
| Runs (the other recordings) | 12,152 calls (`stage1/rec/kb` 3,252, `stage1/rec/fuel` 2,508, `stage1/rec/trails` 1,842 and 7 more) |
| Called from | `AtvPhysics` |
| Calls | `JpBufferAddr` |
| Reads | `$D778` (`AtvHeight`) |
| Writes | `$80DD` (`SpriteY`) |

### `GroundScan` (`$E821`)

**The column scan from HL down (C the pixel mask, B lines)**

Witness: L1 26704 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 1,200 calls, 2,297,636 t-states own (0.15 %) |
| Runs (the other recordings) | 12,152 calls (`stage1/rec/kb` 3,252, `stage1/rec/fuel` 2,508, `stage1/rec/trails` 1,842 and 7 more) |
| Called from | `AtvPhysics`, `RiderGround` |
| Calls | `JpPixelMask` |
| Reads | `$80DD` (`SpriteY`); `$F056`-`$F71B` (`BufferP1+26`, `BufferP1Zeros`, `Trail6Image`, `BufferP1Byte` and 1 more); `$F736`-`$FDFB` (`BufferP2+26`, `TunePlay0`, `TunePlay`, `TuneLoop` and 34 more) |

### `WheelieUp` (`$E838`)

**The nose up two frames (to `$44`)**

Witness: L1 394 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 5 calls, 405 t-states own (0.00 %) |
| Runs (the other recordings) | 389 calls (`stage1/rec/kb` 162, `stage1/rec/warp` 98, `stage1/rec/empty` 67 and 7 more) |
| Called from | `ControlUp` (tail), `JumpControl` |
| Reads | `$D775` (`AtvFrame`) |
| Writes | `$D775` (`AtvFrame`) |

### `WheelieDown` (`$E852`)

**The nose down two frames**

Witness: L1 680 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 35 calls, 2,315 t-states own (0.00 %) |
| Runs (the other recordings) | 645 calls (`stage1/rec/kb` 178, `stage1/rec/warp` 153, `stage1/rec/trails` 71 and 7 more) |
| Called from | `AtvPhysics` (tail) |
| Reads | `$D775` (`AtvFrame`) |
| Writes | `$D775` (`AtvFrame`) |

### `Tumble` (`$E89C`)

**The tumble: 24 passes of TumbleFrames, slowing; then upright (`$44`) on the ground, stopped**

Witness: L1 6676 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

[Animation: `Tumble` at work](img/routines/Tumble.gif)

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 600 calls, 24,124 t-states own (0.00 %) |
| Runs (the other recordings) | 6,076 calls (`stage1/rec/kb` 1,626, `stage1/rec/fuel` 1,254, `stage1/rec/trails` 921 and 7 more) |
| Called from | `Update` |
| Calls | `Stop` (tail), `SlowDown`, `OnGround` |
| Reads | `$D6C4` (`GroundY`); `$D778` (`AtvHeight`); `$D797` (`TumbleCount`); `$E86C`-`$E890` (`TumbleFrames`, `TumbleHeights`) |
| Writes | `$D775`-`$D778` (`AtvFrame`, `Facing`, `AtvX`, `AtvHeight`); `$D797` (`TumbleCount`) |

### `RiderGroundMounted` (`$E90C`)

**RiderGround under the mounted rider**

Witness: L1 2325 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 55 calls, 3,520 t-states own (0.00 %) |
| Runs (the other recordings) | 2,270 calls (`stage1/rec/trails` 631, `stage1/rec/kb` 504, `stage1/rec/warp` 436 and 7 more) |
| Called from | `RiderUpdate` |
| Calls | `RiderGround` (tail) |
| Reads | `$D786` (`RiderHeight`) |
| Writes | `$80DD` (`SpriteY`) |

### `RiderGround` (`$E91C`)

**RiderGround under the rider on foot**

Witness: L1 4351 (c1, empty, fuel, kb, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 545 calls, 103,978 t-states own (0.01 %) |
| Runs (the other recordings) | 3,806 calls (`stage1/rec/fuel` 1,128, `stage1/rec/kb` 1,122, `stage1/rec/trail1` 558 and 7 more) |
| Called from | `RiderUpdate` (tail), `RiderGroundMounted` (tail), `FallRider`, `Thrown` |
| Calls | `JpBufferAddr`, `DrawRider`, `GroundScan` |
| Reads | `$D784`-`$D786` (`RiderFacing`, `RiderX`, `RiderHeight`) |
| Writes | `$80DB`-`$80DD` (`SpriteX`, `SpriteY`); `$D7A0` (`GroundBelowRider`) |

### `Crash` (`$E94C`)

**A crash: back one step, SlowDown; then under 10 stop, 10-14 stop and throw, 15 and up tumble and throw (the speed after the -2)**

c1: 19 crashes (trail1, fuel, trails: see NOTES).

Witness: L1 21 (c1, fuel, kb, speedcrash, trail1, trails, wallcrash, warp).

[Animation: `Crash` at work](img/routines/Crash.gif)

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 8 calls, 1,281 t-states own (0.00 %) |
| Runs (the other recordings) | 13 calls (`stage1/rec/warp` 4, `stage1/rec/fuel` 3, `stage1/rec/kb` 2 and 4 more) |
| Called from | `AtvPhysics` (tail), `CrashIfAir` (tail) |
| Calls | `Advance`, `Stop`, `SlowDown`, `Throw` |
| Reads | `$D776`-`$D77B` (`Facing`, `AtvX`, `AtvHeight`, `PrevHeight` and 1 more); `$D797` (`TumbleCount`) |
| Writes | `$D776`-`$D778` (`Facing`, `AtvX`, `AtvHeight`); `$D797` (`TumbleCount`) |

### `FallRider` (`$E991`)

**The rider falling after ThrowOff (FallPhase 1-5; recording throwoff: 35 runs)**

Known only from the code.

Witness: L1 35 (throwoff).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 35 calls (`stage1/rec/throwoff` 35) |
| Called from | `RiderUpdate` (tail) |
| Calls | `DrawRider`, `SlowDown`, `RiderGround` |
| Reads | `$D77B`-`$D786` (`Speed`, `Fuel`, `SpeedBarLen`, `FuelBar` and 7 more); `$D798`-`$D7A0` (`FallPhase`, `ThrowSpeed`, `EngineNote`, `Bonus` and 2 more); `$E319`-`$E31C` (`FallSteps`) |
| Writes | `$D783`-`$D798` (`RiderFrame`, `RiderFacing`, `RiderX`, `RiderHeight` and 11 more) |

### `RiderToGround` (`$E9E3`)

**RiderHeight - E, not below the ground**

Witness: L1 155 (c1, fuel, kb, speedcrash, throwoff, trail1, trails, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 13 calls, 961 t-states own (0.00 %) |
| Runs (the other recordings) | 133 calls (`stage1/rec/fuel` 32, `stage1/rec/warp` 30, `stage1/rec/kb` 28 and 4 more) |
| Called from | `Thrown` |
| Calls | `DrawRider` |
| Reads | `$D786` (`RiderHeight`); `$D7A0` (`GroundBelowRider`) |
| Writes | `$D786` (`RiderHeight`) |

### `Throw` (`$E9FA`)

**Throw the rider off: ThrowSpeed `$F8` - speed / 8, on foot**

Witness: L1 14 (c1, fuel, kb, speedcrash, trail1, trails, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 2 calls, 199 t-states own (0.00 %) |
| Runs (the other recordings) | 12 calls (`stage1/rec/fuel` 3, `stage1/rec/warp` 3, `stage1/rec/kb` 2 and 4 more) |
| Called from | `Crash` |
| Reads | `$D774`-`$D77B` (`Mounted`, `AtvFrame`, `Facing`, `AtvX` and 3 more); `$D799` (`ThrowSpeed`) |
| Writes | `$D774` (`Mounted`); `$D799` (`ThrowSpeed`) |

### `Thrown` (`$EA21`)

**The thrown rider's flight: forwards 4 a pass, up then down, the tumbling frames `$5E-$64`; lying (`$77`) when he lands**

Witness: L1 259 (c1, fuel, kb, speedcrash, trail1, trails, wallcrash, warp).

[Animation: `Thrown` at work](img/routines/Thrown.gif)

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 22 calls, 7,601 t-states own (0.00 %) |
| Runs (the other recordings) | 237 calls (`stage1/rec/fuel` 58, `stage1/rec/warp` 56, `stage1/rec/kb` 46 and 4 more) |
| Called from | `RiderUpdate` (tail) |
| Calls | `DrawRider`, `RiderGround`, `RiderToGround`, `FlightStep` |
| Reads | `$D783`-`$D786` (`RiderFrame`, `RiderFacing`, `RiderX`, `RiderHeight`); `$D799`-`$D7A0` (`ThrowSpeed`, `EngineNote`, `Bonus`, `LapTime` and 1 more) |
| Writes | `$D783`-`$D786` (`RiderFrame`, `RiderFacing`, `RiderX`, `RiderHeight`); `$D799` (`ThrowSpeed`) |

### `FlightStep` (`$EAAE`)

**E = FallSteps[min(A, 5) - 1]**

Witness: L1 259 (c1, fuel, kb, speedcrash, trail1, trails, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 22 calls, 1,674 t-states own (0.00 %) |
| Runs (the other recordings) | 237 calls (`stage1/rec/fuel` 58, `stage1/rec/warp` 56, `stage1/rec/kb` 46 and 4 more) |
| Called from | `Thrown` |
| Reads | `$E319`-`$E31D` (`FallSteps`) |

## entry

`src/game/entry.asm`

### `GameEntry` (`$D7D6`)

**Copy the tune player and trail 6 out, initialise, set IM 2, then the outer loop: Title, NewGame, CheckHiScore**

Entered from the loader's JP `$D6B0` (c1 frame 14 100). LDIR `$F850-$FDFA` to `$5B00` (`$5AB` bytes), `$F230-$F4B9` to `$60AC` (`$28A` bytes); DI, SP = `$FFDC`, Init, SetupIm2.

Witness: L1 1 (c1).

[Animation: `GameEntry` at work](img/routines/GameEntry.gif)

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 1 call, 58,478 t-states own (0.00 %) |
| Runs (the other recordings) | run into, not called (`stage1/rec/trail1`, `stage1/rec/warp`, `stage1/rec/kb` and 7 more) |
| Called from | `WaitKey60`, `EntryJumps` (tail) |
| Calls | `MenuTable`, `JpCheckHiScore`, `NewGame`, `Init`, `SetupIm2` |
| Reads | `$F230`-`$F4B9` (`Trail6Image`); `$F850`-`$FDFA` (`TunePlay0`, `TunePlay`, `TuneLoop`, `TuneInterrupt` and 33 more) |
| Writes | `$5B00`-`$6335` (system); `$8084`-`$8085` (`AttrBase`); `$D6BA`-`$D6BB` (`SavedSp0`) |

## sound

`src/game/sound.asm`

### `TunePlay0` (`$F850`)

**LD A,0: the start of an entry point for tune 0 that no one calls (Title and TrailEnd call TunePlay)**

Known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `TunePlay` (`$F852`)

**Play tune A: the channels' sequences, the own IM 2 table and vector, the loop until the tune or a key ends it**

TuneNumber (`$FB57`) = A; DI; the three sequence pointers from TuneTable; the attack/decay bytes reset; `$FE00-$FF00` = `$FD`, I = `$FE`, IM 2, `$FDFD` = JP TuneInterrupt; the first sequence of each channel; then TuneLoop. Title (c1: 4) and TrailEnd (trail1, trails: 9) call it.

Witness: L1 17 (c1, kb, menu, trail1, trails, turn, wallcrash, warp).

[Animation: `TunePlay` at work](img/routines/TunePlay.gif)

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 2 calls, 14,180 t-states own (0.00 %) |
| Runs (the other recordings) | 15 calls (`stage1/rec/warp` 8, `stage1/rec/menu` 2, `stage1/rec/kb` 1 and 4 more) |
| Called from | `MenuLoop`, `TrailEnd` |
| Calls | `TuneLoop`, `TuneKeyCheck` (tail), `NextSequenceA`, `NextSequenceB`, `NextSequenceD`, `TuneEntry` |
| Writes | `$F903`-`$F90C` (`ChannelAOn+1`, `l_F908`, `ChannelAOff`); `$F952`-`$F95B` (`ChannelBOn+1`, `l_F957`, `ChannelBOff`); `$F986`-`$F98A` (`TuneStop+8`); `$FA56` (`l_FA52+4`); `$FA72` (`l_FA6E+4`); `$FAFA`-`$FAFB` (`NextSequenceA+1`); 5 more ranges |

### `TuneLoop` (`$F8B5`)

**The two channels: count down each channel's period, toggle the speaker, read the next note or command at the end of its length**

Witness: L1 17 (c1, kb, menu, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 2 calls, 98,593,074 t-states own (6.30 %) |
| Runs (the other recordings) | 15 calls (`stage1/rec/warp` 8, `stage1/rec/menu` 2, `stage1/rec/trail1` 1 and 4 more) |
| Called from | `TunePlay`, `CommandsB` (tail), `SetTransposeB` (tail) |
| Calls | `ChannelBCommand` (tail), `ChannelACommand` (tail), `Envelope`, `NoteLookup` |
| Reads | `$F8BD` (`l_F8BD`); `$F903` (`ChannelAOn+1`); `$F952` (`ChannelBOn+1`); `$FC0E`-`$FD61` (`SequencesA0+84`); `$FD8C`-`$FDF9` (`SequencesA0+466`) |
| Writes | `$F8C5`-`$F8C6` (`ChannelAPtr+1`); `$F8FC`-`$F915` (`l_F8F8+4`, `l_F8FF`, `ChannelAOn`, `l_F908` and 3 more); `$F94B`-`$F956` (`l_F946+5`, `l_F94E`, `ChannelBOn`); `$FAC7` (`Envelope+1`); `$FAE0` (`EnvelopeStep+1`); `$FFFC`-`$FFFD` (`work space $FFFC+`) |
| Ports out | `$00FE`, `$18FE` |

### `TuneInterrupt` (`$F961`)

**The tune's IM 2 handler: count the channels' note timers, the drums every 12 frames, the hook**

Witness: L1 7111 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 1,517 calls, 227,077 t-states own (0.01 %) |
| Runs (the other recordings) | 5,594 calls (`stage1/rec/menu` 2,560, `stage1/rec/warp` 1,691, `stage1/rec/trail1` 800 and 8 more) |
| Called from | `TuneVector` (tail) |
| Calls | `MenuTick`, `Drums` |

### `TuneKeyCheck` (`$F977`)

**Any key: stop the tune**

Witness: L1 5420 (c1, empty, fuel, kb, menu, speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 1,517 calls, 56,224 t-states own (0.00 %) |
| Runs (the other recordings) | 3,903 calls (`stage1/rec/menu` 2,559, `stage1/rec/trail1` 800, `stage1/rec/warp` 508 and 8 more) |
| Called from | `MenuTick` (tail), `TunePlay` (tail) |
| Calls | `MenuLoop` |
| Writes | `$FDFE`-`$FDFF` (`TuneVector+1`) |
| Ports in | `$00FE` |

### `ChannelBCommand` (`$F98E`)

**Channel B's command byte: dispatch by CommandJump**

Witness: L1 846 (c1, kb, menu, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 159 calls, 8,109 t-states own (0.00 %) |
| Runs (the other recordings) | 687 calls (`stage1/rec/warp` 249, `stage1/rec/menu` 220, `stage1/rec/trail1` 146 and 4 more) |
| Called from | `TuneLoop` (tail), `CommandJump` |
| Calls | `CommandsB` (tail), `SetTransposeB` (tail), `CommandJump` |

### `ChannelACommand` (`$F9A7`)

**Channel A's command byte**

Witness: L1 730 (c1, kb, menu, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 168 calls, 8,568 t-states own (0.00 %) |
| Runs (the other recordings) | 562 calls (`stage1/rec/menu` 283, `stage1/rec/warp` 147, `stage1/rec/trail1` 89 and 4 more) |
| Called from | `TuneLoop` (tail), `CommandJump` |
| Calls | `CommandsB` (tail), `CommandJump` |

### `UnusedCommandA4` (`$F9BA`)

**Channel A's command 4: JP SetTransposeA, the shared transposition (no tune uses it)**

Known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CommandEnd` (`$F9BD`)

**POP HL; RET: channel A's end of the tune (`$85`); no recording reaches it: channel B's twin at `$F9A4` ends the tunes in them (trails 1, warp 7, kb 1)**

Known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `CommandsB` (`$F9BF`)

**Channel B's commands: decay, attack, length, next**

Witness: L1 37 (c1, kb, menu, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 7 calls, 24,719 t-states own (0.00 %) |
| Runs (the other recordings) | 30 calls (`stage1/rec/menu` 11, `stage1/rec/warp` 10, `stage1/rec/trail1` 5 and 4 more) |
| Called from | `ChannelBCommand` (tail), `ChannelACommand` (tail) |
| Calls | `TuneLoop` (tail), `NextSequenceA`, `NextSequenceB` |
| Reads | `$F903` (`ChannelAOn+1`); `$F952` (`ChannelBOn+1`); `$FC0F`-`$FC64` (`SequencesA0+85`); `$FCC9`-`$FCCB` (`SequencesA0+271`); `$FD4E`-`$FD5F` (`SequencesA0+404`); `$FD8D`-`$FDBD` (`SequencesA0+467`); 1 more ranges |
| Writes | `$F8F0` (`l_F8EC+4`); `$F903` (`ChannelAOn+1`); `$F93E` (`l_F93A+4`); `$F952` (`ChannelBOn+1`); `$FACE` (`Envelope+8`); `$FAE6` (`EnvelopeStep+7`) |

### `SetTransposeA` (`$FA17`)

**The shared transposition (the one byte both channels add) from channel A's stream (no tune uses it)**

Known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `SetTransposeB` (`$FA20`)

**Channel B's transposition (TransposeB at `$FB69`)**

Witness: L1 2 (menu).

| | |
| --- | --- |
| Runs | not reached in `stage1/rec/c1`; in the other recordings 2 calls (`stage1/rec/menu` 2) |
| Called from | `ChannelBCommand` (tail) |
| Calls | `TuneLoop` (tail) |
| Reads | `$FDF5`-`$FDF8` (`SequencesA0+571`) |
| Writes | `$FB69` (`TransposeB+1`) |

### `Drums` (`$FA29`)

**The drums' stream, a byte every 12 interrupts or as DrumSpeed sets (from TuneInterrupt): the byte AND `$7F` picks 0 next sequence, 1 rest, 2 DrumUnused2, 3 DrumSpeed, 4 DrumUnused, 5 nothing, 6 DrumNoise, 7 DrumHit**

Witness: L1 1157 (c1, kb, menu, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 270 calls, 19,995 t-states own (0.00 %) |
| Runs (the other recordings) | 887 calls (`stage1/rec/menu` 455, `stage1/rec/warp` 225, `stage1/rec/trail1` 143 and 4 more) |
| Called from | `TuneInterrupt`, `DrumNext` (tail), `DrumSpeed` (tail), `CommandJump` |
| Calls | `DrumNext` (tail), `CommandJump` |
| Reads | `$FD62`-`$FD7D` (`SequencesA0+424`); `$FDF0`-`$FDF2` (`SequencesA0+566`) |
| Writes | `$FA2C`-`$FA2D` (`DrumPtr+1`) |

### `DrumJump2` (`$FA3E`)

**Drum command 2: JP DrumUnused2 (no tune uses it)**

Known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DrumJump3` (`$FA41`)

**Drum command 3: JP DrumSpeed**

Witness: L1 480 (c1, kb, menu, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 112 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 1,120 t-states own (0.00 %) |
| Runs (the other recordings) | 368 runs of its first instruction, entered by a jump (`stage1/rec/menu` 188, `stage1/rec/warp` 94, `stage1/rec/trail1` 59 and 4 more) |
| Called from | `CommandJump` |
| Calls | `DrumSpeed` (tail) |

### `DrumJump4` (`$FA44`)

**Drum command 4: JP DrumUnused (no tune uses it)**

Known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DrumJump5` (`$FA47`)

**Drum command 5: RET (no tune uses it)**

Known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DrumJump6` (`$FA4A`)

**Drum commands 6 and 7: JP DrumNoise, JP DrumHit**

Witness: L1 470 (c1, kb, menu, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 112 runs of its first instruction (entered by a jump or by running on, no routine of its own in the L1), 1,580 t-states own (0.00 %) |
| Runs (the other recordings) | 358 runs of its first instruction, entered by a jump (`stage1/rec/menu` 188, `stage1/rec/warp` 87, `stage1/rec/trail1` 59 and 4 more) |
| Called from | `CommandJump` |
| Calls | `DrumNoise` (tail), `DrumHit` (tail) |

### `DrumUnused` (`$FA50`)

**A drum sound no tune uses: 128 bytes of the ROM sent to the speaker**

Known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DrumNoise` (`$FA5D`)

**A noise: the ROM's bytes from `$005C` sent to the speaker until a zero**

Witness: L1 470 (c1, kb, menu, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 112 calls, 3,975,116 t-states own (0.25 %) |
| Runs (the other recordings) | 358 calls (`stage1/rec/menu` 188, `stage1/rec/warp` 87, `stage1/rec/trail1` 59 and 4 more) |
| Called from | `DrumJump6` (tail) |
| Ports out | `$00FE`, `$08FE`, `$10FE`, `$18FE` |

### `DrumUnused2` (`$FA6C`)

**A second unused drum sound**

Known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DrumNext` (`$FA7C`)

**The drums' next sequence**

Witness: L1 64 (c1, kb, menu, trail1, trails, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 15 calls, 435 t-states own (0.00 %) |
| Runs (the other recordings) | 49 calls (`stage1/rec/menu` 26, `stage1/rec/warp` 12, `stage1/rec/trail1` 8 and 3 more) |
| Called from | `Drums` (tail) |
| Calls | `Drums` (tail), `NextSequenceD` |

### `DrumHit` (`$FA81`)

**A drum: 30 clicks of a falling pitch**

Witness: L1 197 (c1, kb, menu, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 46 calls, 2,646,113 t-states own (0.17 %) |
| Runs (the other recordings) | 151 calls (`stage1/rec/menu` 79, `stage1/rec/warp` 37, `stage1/rec/trail1` 25 and 4 more) |
| Called from | `DrumJump6` (tail) |
| Reads | `$F877` (`DrumBorder+1`); `$FA2C`-`$FA2D` (`DrumPtr+1`); `$FD6C`-`$FD7C` (`SequencesA0+434`) |
| Writes | `$FA2C`-`$FA2D` (`DrumPtr+1`) |
| Ports out | `$00FE`, `$18FE` |

### `DrumSpeed` (`$FAA9`)

**The drums' speed (3 x the byte)**

Witness: L1 480 (c1, kb, menu, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 112 calls, 14,224 t-states own (0.00 %) |
| Runs (the other recordings) | 368 calls (`stage1/rec/menu` 188, `stage1/rec/warp` 94, `stage1/rec/trail1` 59 and 4 more) |
| Called from | `DrumJump3` (tail) |
| Calls | `Drums` (tail) |
| Reads | `$FA2C`-`$FA2D` (`DrumPtr+1`); `$FD63`-`$FD78` (`SequencesA0+425`); `$FDF1` (`SequencesA0+567`) |
| Writes | `$FA2A`-`$FA2D` (`Drums+1`, `DrumPtr`) |

### `CommandJump` (`$FABC`)

**Jump to the (A AND `$7F`)th JP after the caller**

Witness: L1 2797 (c1, kb, menu, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 612 calls, 28,152 t-states own (0.00 %) |
| Runs (the other recordings) | 2,185 calls (`stage1/rec/menu` 984, `stage1/rec/warp` 633, `stage1/rec/trail1` 386 and 4 more) |
| Called from | `ChannelBCommand`, `ChannelACommand`, `Drums` |
| Calls | `ChannelBCommand`, `ChannelACommand`, `Drums`, `DrumJump3`, `DrumJump6` |

### `Envelope` (`$FAC6`)

**The channels' note shapes: the attack and decay counters**

Witness: L1 3257 (c1, kb, menu, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 748 calls, 107,143 t-states own (0.01 %) |
| Runs (the other recordings) | 2,509 calls (`stage1/rec/menu` 1,185, `stage1/rec/warp` 716, `stage1/rec/trail1` 401 and 4 more) |
| Called from | `TuneLoop` |
| Reads | `$F8FE`-`$F907` (`l_F8F8+6`, `l_F8FF`, `ChannelAOn`); `$F94D`-`$F956` (`l_F946+7`, `l_F94E`, `ChannelBOn`) |
| Writes | `$F8FE`-`$F907` (`l_F8F8+6`, `l_F8FF`, `ChannelAOn`); `$F94D`-`$F956` (`l_F946+7`, `l_F94E`, `ChannelBOn`); `$FAC7` (`Envelope+1`); `$FAE0` (`EnvelopeStep+1`) |

### `NextSequenceA` (`$FAF9`)

**Channel A's next sequence (the list's end: the first again)**

Witness: L1 72 (c1, kb, menu, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 17 calls, 1,547 t-states own (0.00 %) |
| Runs (the other recordings) | 54 calls (`stage1/rec/menu` 28, `stage1/rec/warp` 13, `stage1/rec/trail1` 9 and 4 more) |
| Called from | `TunePlay`, `CommandsB` |
| Calls | `TuneEntry` |
| Reads | `$FBAE`-`$FBEB` (`TuneTable`, `SequencesA0`); `$FD7E`-`$FD7F` (`SequencesA0+452`) |
| Writes | `$F8C5`-`$F8C6` (`ChannelAPtr+1`); `$FAFA`-`$FAFB` (`NextSequenceA+1`) |

### `NextSequenceB` (`$FB16`)

**Channel B's next sequence**

Witness: L1 56 (c1, kb, menu, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 11 calls, 1,001 t-states own (0.00 %) |
| Runs (the other recordings) | 44 calls (`stage1/rec/menu` 18, `stage1/rec/warp` 13, `stage1/rec/trail1` 9 and 4 more) |
| Called from | `TunePlay`, `CommandsB` |
| Calls | `TuneEntry` |
| Reads | `$FBB0`-`$FBB1` (`TuneTable+2`); `$FBEC`-`$FC09` (`SequencesA0+50`); `$FD82`-`$FD83` (`SequencesA0+456`) |
| Writes | `$F914`-`$F915` (`ChannelBPtr+1`); `$FB17`-`$FB18` (`NextSequenceB+1`) |

### `NextSequenceD` (`$FB35`)

**The drums' next sequence**

Witness: L1 135 (c1, kb, menu, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 17 calls, 4,217 t-states own (0.00 %) |
| Runs (the other recordings) | 64 calls (`stage1/rec/menu` 28, `stage1/rec/warp` 20, `stage1/rec/trail1` 9 and 4 more) |
| Called from | `TunePlay`, `DrumNext` |
| Calls | `TuneEntry` |
| Reads | `$FBB2`-`$FBB3` (`TuneTable+4`); `$FC0A`-`$FC0D` (`SequencesA0+80`); `$FD86`-`$FD89` (`SequencesA0+460`) |
| Writes | `$FA2C`-`$FA2D` (`DrumPtr+1`); `$FB36`-`$FB37` (`NextSequenceD+1`) |

### `TuneEntry` (`$FB56`)

**HL = TuneTable + 6 x TuneNumber**

Witness: L1 73 (c1, kb, menu, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 17 calls, 884 t-states own (0.00 %) |
| Runs (the other recordings) | 56 calls (`stage1/rec/menu` 30, `stage1/rec/warp` 13, `stage1/rec/trail1` 9 and 4 more) |
| Called from | `TunePlay`, `NextSequenceA`, `NextSequenceB`, `NextSequenceD` |

### `NoteLookup` (`$FB64`)

**A = NoteTable's period for the note A + TransposeB**

Witness: L1 2000 (c1, kb, menu, trail1, trails, turn, wallcrash, warp).

| | |
| --- | --- |
| Runs (c1: a 48K from power-on, the original TZX at signal speed, the title, the menu, trail 1 to TIME OUT) | 426 calls, 31,950 t-states own (0.00 %) |
| Runs (the other recordings) | 1,574 calls (`stage1/rec/menu` 732, `stage1/rec/warp` 472, `stage1/rec/trail1` 221 and 4 more) |
| Called from | `TuneLoop` |
| Reads | `$FB72`-`$FB97` (`NoteTable`) |
