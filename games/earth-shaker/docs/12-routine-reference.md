# 12. Routine reference

Every code entry of the game, in address order by module (`src/game/<module>.asm`). The name, the title and
the description are the source's (`src/game/game.ann`); the rest is what the recordings saw: `work/stage1/c1` (c1: power-on, the covertape side at ROM speed, the menu and play). They are local, not in the repository; the WALKTHROUGH's commands rebuild them.
Runs count the calls of the entry itself; the time is its own t-states (callees excluded) and their share
of the recording. Memory ranges name the label at or below their first byte (inner labels too, `Label+offset`)
and the entries they cover. The interrupt's acceptance (the vector read, the return address pushed) is
the handler's, not the interrupted routine's. An entry no recording reached says so; one the case's other
recordings ran gives their calls.
Written by `kit/refdocs.py`; edit `src/game/game.ann`, then run `kit/mkgame.py --case . --install`
(see [3. Build and load](03-build-and-load.md)) and `kit/refdocs.py --case .`.

| Module | Entries | Code entries |
| --- | --- | --- |
| [`hiscore`](#hiscore) | `$6D42`-`$6EF3`, `$7F00`-`$7FF9`, `$8AAC`-`$8B1F`, `$8B78`-`$8BE4`, `$8D5D`-`$8D65`, `$AA00`-`$AAFF`, `$B26C`-`$B2FF` | 15 of 22 |
| [`music`](#music) | `$6EF4`-`$72FF`, `$88CE`-`$8963`, `$8A35`-`$8A3B`, `$AC5F`-`$B26B`, `$BB80`-`$BC91`, `$EE24`-`$EEFF`, `$F100`-`$FADF` | 4 of 24 |
| [`effects`](#effects) | `$7300`-`$7EFF`, `$8228`-`$8264`, `$82F9`-`$8314`, `$8548`-`$8555`, `$861F`-`$8653`, `$9072`-`$9090`, `$90A0`-`$90B1`, `$9230`-`$926D`, `$A713`-`$A791`, `$E740`-`$E78B`, `$E7A9`-`$E7F4`, `$E860`-`$E868`, `$E87B`-`$E8E0` | 20 of 28 |
| [`cells`](#cells) | `$7FFA`-`$7FFF`, `$8075`-`$81B8`, `$937E`-`$93A4`, `$9AA5`-`$9ACB`, `$9DFC`-`$9E19`, `$A655`-`$A712`, `$A7A0`-`$A814`, `$E78C`-`$E7A8`, `$E7F5`-`$E7FD`, `$E83A`-`$E856`, `$FB70`-`$FB9F` | 23 of 34 |
| [`renderer`](#renderer) | `$8000`-`$8058`, `$81B9`-`$81CB`, `$8265`-`$82B5`, `$8964`-`$8978`, `$8D46`-`$8D5C`, `$8D66`-`$8DE2`, `$8F60`-`$903E`, `$90B2`-`$914B`, `$9B08`-`$9DFB`, `$9E1A`-`$A5FF`, `$ED28`-`$EE23`, `$EF00`-`$F0FF`, `$FAE0`-`$FB6F`, `$FBA0`-`$FBFF` | 12 of 26 |
| [`mapscreen`](#mapscreen) | `$8059`-`$8074`, `$81CC`-`$81E6`, `$9A00`-`$9AA4`, `$E8E1`-`$EAC2` | 10 of 18 |
| [`main`](#main) | `$81E7`-`$8227`, `$82E6`-`$82F8`, `$85F1`-`$860D`, `$8687`-`$8758`, `$8885`-`$88CD`, `$89EA`-`$8A34`, `$8BE5`-`$8BEB`, `$903F`-`$9071`, `$91B9`-`$91C0`, `$92D4`-`$9304`, `$93A5`-`$93B5`, `$A615`-`$A63D`, `$A64B`-`$A654`, `$A792`-`$A79F`, `$A815`-`$A8D4`, `$AB6A`-`$AC2D`, `$FD00`-`$FFFF` | 31 of 77 |
| [`unpack`](#unpack) | `$82B6`-`$82E5`, `$9305`-`$934E`, `$A600`-`$A614` | 5 of 5 |
| [`hud`](#hud) | `$8315`-`$83C2`, `$85AD`-`$85CE`, `$8654`-`$8686`, `$89A7`-`$89E9`, `$8BEC`-`$8C0D`, `$91F7`-`$922F`, `$A8D5`-`$A8FF`, `$A9D7`-`$A9FF`, `$BB00`-`$BB7F`, `$BC92`-`$BFFF` | 21 of 30 |
| [`player`](#player) | `$83C3`-`$8547`, `$8556`-`$85AC`, `$8759`-`$8884`, `$914C`-`$91B8`, `$91C1`-`$91F6`, `$926E`-`$92D3`, `$934F`-`$937D`, `$93B6`-`$96FF`, `$9980`-`$99BF`, `$A63E`-`$A64A`, `$E7FE`-`$E839`, `$E857`-`$E85F`, `$E869`-`$E87A` | 57 of 64 |
| [`menu`](#menu) | `$85CF`-`$85D5`, `$860E`-`$861E`, `$8979`-`$89A6`, `$8A3C`-`$8AAB`, `$8B20`-`$8B77`, `$8DE3`-`$8DFE`, `$9091`-`$909F`, `$AB00`-`$AB69`, `$AC2E`-`$AC5E`, `$B300`-`$BAFF`, `$FC00`-`$FCFF` | 11 of 17 |
| [`password`](#password) | `$85D6`-`$85F0`, `$8DFF`-`$8F5F`, `$9700`-`$997F`, `$99C0`-`$99FF`, `$9ACC`-`$9B07` | 10 of 15 |
| [`keys`](#keys) | `$8C0E`-`$8D45`, `$A900`-`$A9D6`, `$EAC3`-`$ED27` | 9 of 16 |
| [`cavedata`](11-data-reference.md#cavedata) | `$C000`-`$E73F` | 0 of 1 |

## hiscore

`src/game/hiscore.asm`

### `EnterName` (`$7F00`)

**Type a name into a high-score record**

HL = the record's name field (9 bytes), B = the record (1-5; the screen row is 2B + 10). Each key comes from WaitKey `$8C1D` (KeyTable `$A900` gives its character) and is printed and stored; '0' deletes the last character, 'e' (ENTER) ends. Writes the name in place.

Witness: L1 1 (hiscore).

[Animation: `EnterName` at work](img/routines/EnterName.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/hiscore` 1) |

### `HiScoreCompare` (`$7F60`)

**Compare the score with high-score record B**

B = the record (1-5). HL = HiScoreTable + 15 x (B - 1), DE = ScoreDigits `$FD94`; the 6 digits are compared from the first. Out: carry set when the score is below the record, else carry clear.

Witness: L1 9 (hiscore, lives).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 9 calls (`stage1/lives` 5, `stage1/hiscore` 4) |

### `HiScoreInsert` (`$7F7A`)

**Put the score into the table if it is not below a record**

Tries records 1-5 with HiScoreCompare `$7F60`. At the first the score is not below: ClearScreen, the lower records move down one (the fifth is lost), the score digits and a blank name go in, EnterName `$7F00`. Returns with no change when every record is above the score.

Witness: L1 2 (hiscore, lives).

[Animation: `HiScoreInsert` at work](img/routines/HiScoreInsert.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2 calls (`stage1/hiscore` 1, `stage1/lives` 1) |

### `GameOver` (`$7FF3`)

**The end of a game: the high-score check, then the game-over screen**

HiScoreInsert `$7F7A`, GameOverScreen `$8BD5`. Called from NewGame `$8BE5` after the last life.

Witness: L1 2 (hiscore, lives).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2 calls (`stage1/lives` 1, `stage1/hiscore` 1) |

### `ScrollBottomLine` (`$8AAC`)

**Scroll the bottom character line one pixel left**

Witness: L1 3472 (menu).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3,472 calls (`stage1/menu` 3,472) |

### `DrawTitle` (`$8AC8`)

**Clear the screen, print and colour the menu, show the logo**

Pixels 0, attributes `$47`, the last attribute 0; ShowMenuTexts `$8A3C`, ColourMenuTexts `$8A83`, ShowLogo `$9091`.

Witness: L1 9 (c1, lives, menu).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 5 calls, 923,664 t-states own (0.08 %) |
| Called from | `GameEntry` |
| Calls | `ShowMenuTexts`, `ColourMenuTexts`, `ShowLogo` |
| Reads | `$4000`-`$5AFE` (screen) |
| Writes | `$4000`-`$5AFF` (screen) |

### `RunScroller` (`$8AEB`)

**Run the scroller until a key 1-5 or the text's end**

Out: the zero flag clear when a key stopped it.

Witness: L1 1 (menu).

[Animation: `RunScroller` at work](img/routines/RunScroller.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/menu` 1) |

### `PlayGameOverTune` (`$8B78`)

**Play GameOverTune `$AA00`**

Witness: L1 2 (hiscore, lives).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2 calls (`stage1/lives` 1, `stage1/hiscore` 1) |

### `ShowGameOver` (`$8B7F`)

**Print GAME OVER, the score and the level reached**

Witness: L1 2 (hiscore, lives).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2 calls (`stage1/hiscore` 1, `stage1/lives` 1) |

### `GameOverScreen` (`$8BD5`)

**The game-over screen: clear, the texts, the tune, wait for a key**

ClearScreen, ShowGameOver `$8B7F`, PlayGameOverTune `$8B78`, ROM KEY-SCAN until a key.

Witness: L1 2 (hiscore, lives).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2 calls (`stage1/hiscore` 1, `stage1/lives` 1) |

### `ShowHiScoreTable` (`$B26C`)

**Print the 5 records' scores and names**

Witness: L1 2 (hiscore, menu).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2 calls (`stage1/menu` 1, `stage1/hiscore` 1) |

### `ShowHiScoreTitle` (`$B294`)

**Print HI-SCORES and the table**

Witness: L1 2 (hiscore, menu).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2 calls (`stage1/hiscore` 1, `stage1/menu` 1) |

### `ColourHiScores` (`$B2A3`)

**Colour and print the high-score lines**

Witness: L1 2 (hiscore, menu).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2 calls (`stage1/hiscore` 1, `stage1/menu` 1) |

### `ClearHiScoreArea` (`$B2C9`)

**Clear rows 9-21 with BlankGraphic**

C runs from 32 down to 0, so each row's 33rd glyph spills into column 0 of the next row (row 15's into row 8, row 21's into row 22).

Witness: L1 2 (menu).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2 calls (`stage1/menu` 2) |

### `ShowHiScores` (`$B2E4`)

**The high scores with the scroller, then the menu again**

Out: RunScroller's flags, kept by PUSH AF / POP AF: NZ when a key 1-5 stopped the scroller, and MenuKeys `$8B29` then acts on that key at once; Z when the text ran out, and the title tune plays again.

Witness: L1 1 (menu).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/menu` 1) |

## music

`src/game/music.asm`

### `PlayTune` (`$88CE`)

**Play the tune at HL with interrupts off; a key 1-5 stops it**

See the module header. Out: HL at the byte that ended the tune, interrupts on.

Witness: L1 66 (c1, hiscore, lives, menu, timer, rzx x32).

[Animation: `PlayTune` at work](img/routines/PlayTune.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 8 calls, 111,912,965 t-states own (10.23 %) |
| Called from | `PlayTitleTune`, `PlayCaveTune` |
| Reads | `$AD00`-`$ADB0` (`TitleTune`); `$BB80`-`$BBF9` (`CaveTune1`); `$BC2C`-`$BC53` (`NotePeriods+44`) |
| Ports in | `$F7FE` |
| Ports out | `$00FE`, `$10FE`, `$F7FF` |

### `PlayCaveTuneJump` (`$895D`)

**JP PlayCaveTune: the 1990 version's one tune per four caves**

Witness: L1 46 (c1, hiscore, lives, timer, rzx x31).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 3 calls, 30 t-states own (0.00 %) |
| Called from | `CavePlay` |
| Calls | `PlayCaveTune` (tail) |

### `PlayTitleTune` (`$8A35`)

**Play TitleTune `$AD00`**

Witness: L1 10 (c1, lives, menu).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 5 calls, 175 t-states own (0.00 %) |
| Called from | `GameEntry` |
| Calls | `PlayTune` |

### `PlayCaveTune` (`$EE34`)

**Play the tune of the cave's group of four**

Witness: L1 46 (c1, hiscore, lives, timer, rzx x31).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 3 calls, 315 t-states own (0.00 %) |
| Called from | `PlayCaveTuneJump` (tail) |
| Calls | `PlayTune` |
| Reads | `$EE24`-`$EE25` (`CaveTunes`); `$FD91` (`CaveNumber`) |

## effects

`src/game/effects.asm`

### `ThudSound` (`$8228`)

**The landing / push thud, registers kept**

NoiseThud `$E77C` with AF, BC, DE, HL saved.

Witness: L1 3446 (c1, hiscore, rzx x29).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 2 calls, 240 t-states own (0.00 %) |
| Called from | `PassSound` |
| Calls | `NoiseThud` |

### `PassSoundEntry` (`$8250`)

**The pass sound: JP PassSoundJump**

JP PassSoundJump `$E7E5` (the 1990 version moved the choice to PassSound `$E83A`).

Witness: L1 43775 (c1, hiscore, lives, timer, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 264 calls, 2,640 t-states own (0.00 %) |
| Called from | `FizzSound` |
| Calls | `PassSoundJump` (tail) |

### `FallSoundChoice` (`$8253`)

**The fall noise if a boulder or another object fell**

A = BoulderFell `$7FFF` (from PassSound): not 0 plays FallSound `$E7A9`; else ObjectFell `$7FFE` not 0 does.

Witness: L1 40382 (c1, hiscore, lives, timer, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 262 calls, 14,106 t-states own (0.00 %) |
| Called from | `PassSound` (tail) |
| Calls | `FallSound` |
| Reads | `$7FFE` (`ObjectFell`) |

### `GemSound` (`$82F9`)

**The gem sound**

ROM BEEPER HL = `$0200`, DE = 5, then HL = `$0100`, DE = 10.

Witness: L1 1692 (c1, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 2 calls, 270 t-states own (0.00 %) |
| Called from | `CountGem` |

### `DigNoiseLoop` (`$854A`)

**The noise loop: (HL) AND `$18` to port `$FE` for HL down to 0**

Witness: L1 991362 (c1, rzx x31).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `DeathLoop` (`$8630`)

**256 ROM BEEPER notes, periods and lengths from the ROM's bytes**

For L down from 0 (256 steps): HL = the period (the ROM byte at H = 0, L), DE = (L / 4) AND 15.

Witness: L1 255 (c1).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ExitOpenSound` (`$9072`)

**The exit opens: a sweep**

LD C,(HL) then AND `$7F`: the AND acts on A, so C keeps the full ROM byte (a 0 byte gives a 256-turn low half).

Witness: L1 33 (rzx x32).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 33 calls (`stage1/rzx30` 2, `stage1/rzx16` 1, `stage1/rzx09` 1 and 29 more) |

### `RaspSound` (`$90A0`)

**A rasp: the key redefined, a bubble burst**

Witness: L1 146 (c1, menu, rzx x21).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 5 calls, 116,812 t-states own (0.01 %) |
| Called from | `RedefineKeys` |

### `TeleportFlashOut` (`$9230`)

**The teleport: the next attribute frame up**

Witness: L1 928 (rzx x19).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 928 calls (`stage1/rzx26` 224, `stage1/rzx24` 80, `stage1/rzx32` 80 and 16 more) |

### `TeleportFlashIn` (`$924F`)

**The teleport: the next attribute frame down**

Witness: L1 928 (rzx x19).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 928 calls (`stage1/rzx26` 224, `stage1/rzx24` 80, `stage1/rzx32` 80 and 16 more) |

### `Jingle` (`$A713`)

**A self-modified BEEPER sweep**

Witness: L1 81 (c1, menu, rzx x23).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 6 calls, 1,844,062 t-states own (0.17 %) |
| Called from | `SwitchSound` |
| Ports out | `$00FE`, `$18FE` |

### `SwitchSound` (`$A74B`)

**The switch's sound**

Witness: L1 27 (c1, menu, rzx x23).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 2 calls, 372 t-states own (0.00 %) |
| Called from | `ChooseControl` |
| Calls | `Jingle` |
| Writes | `$A720` (`JingleHighShift+1`); `$A737` (`JingleLowShift+1`) |

### `FizzSound` (`$A773`)

**While FizzCount runs down: one beep a pass**

Witness: L1 43775 (c1, hiscore, lives, timer, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 264 calls, 19,020 t-states own (0.00 %) |
| Called from | `PlayCave` |
| Calls | `PassSoundEntry` |
| Reads | `$7FFB` (`FizzCount`) |

### `NoiseBurst` (`$E740`)

**ROM bytes as noise**

Witness: L1 11006 (c1, hiscore, rzx x30).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 6 calls, 252,602 t-states own (0.02 %) |
| Called from | `NoiseThud` |
| Ports out | `$00FE`, `$18FE` |

### `NoiseThud` (`$E77C`)

**The thud: NoiseBurst with a short length**

Witness: L1 3446 (c1, hiscore, rzx x29).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 2 calls, 496 t-states own (0.00 %) |
| Called from | `ThudSound` |
| Calls | `NoiseBurst` |
| Writes | `$E74B` (`NoiseBurstPitch+1`) |

### `FallSound` (`$E7A9`)

**The fall noise**

Witness: L1 3647 (c1, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 1 call, 95,198 t-states own (0.01 %) |
| Called from | `FallSoundChoice` |
| Ports out | `$00FE`, `$18FE` |

### `PassSoundJump` (`$E7E5`)

**JP PassSound**

Witness: L1 43775 (c1, hiscore, lives, timer, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 264 calls, 2,640 t-states own (0.00 %) |
| Called from | `PassSoundEntry` (tail) |
| Calls | `PassSound` (tail) |

### `DigNoiseIfDug` (`$E860`)

**The dig noise when DugEarth**

Witness: L1 20264 (c1, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 49 calls, 2,340 t-states own (0.00 %) |
| Called from | `PlayerStep` |
| Calls | `DigNoise` |
| Reads | `$E857` (`DugEarth`) |

### `TeleportOutEffect` (`$E87B`)

**The teleport out: sound and attribute frames**

Witness: L1 58 (rzx x19).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 58 calls (`stage1/rzx26` 14, `stage1/rzx24` 5, `stage1/rzx32` 5 and 16 more) |

### `TeleportInEffect` (`$E8AE`)

**The teleport in: sound and attribute frames**

Witness: L1 58 (rzx x19).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 58 calls (`stage1/rzx26` 14, `stage1/rzx32` 5, `stage1/rzx24` 5 and 16 more) |

## cells

`src/game/cells.asm`

### `ScanCells` (`$8075`)

**The gravity scan of a pass: clear the fall flags, then ScanCellsBody**

A = 0, JP ClearFallFlags `$E7F5`, which clears BoulderLanded `$E7A8` and BoulderFell `$7FFF` and jumps to ScanCellsBody `$8079`.

Witness: L1 42379 (c1, hiscore, lives, timer, rzx x32).

[Animation: `ScanCells` at work](img/routines/ScanCells.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 265 calls, 3,710 t-states own (0.00 %) |
| Called from | `AntiGravPass` |
| Calls | `ClearFallFlags` (tail) |

### `ScanCellsBody` (`$8079`)

**Walk the grid bottom-up, right to left, and move each falling object**

ObjectFell `$7FFE` = A (0). HL = `$FFE1` (row 18, column 29), DE = HL + 30, 19 rows of 30 cells. A boulder above fire becomes `$15` (the dissolve) and FizzCount `$7FFB` = 7. The cells skipped (see the module header) never reach EarthFallGuard `$9AA6` / MoveObject `$80DB`. The CP (HL) at `$809A` is the earth test SetEarthFalls `$FB81` patches to NOP.

Witness: L1 42379 (c1, hiscore, lives, timer, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 265 calls, 18,445,922 t-states own (1.69 %) |
| Called from | `ClearFallFlags` (tail) |
| Calls | `EarthFallGuard` |
| Reads | `$FDA8`-`$FFFD` (`CaveGrid`) |
| Writes | `$7FFE` (`ObjectFell`) |

### `MoveObject` (`$80DB`)

**Make the object at HL fall into DE, or roll it off**

HL = the object, DE = the cell below, B = the column count left (30 for column 29, 1 for column 0). The cell below empty: the object moves into it, HL gets `$20`; a boulder calls BoulderLandCheck `$E78C`, another object sets ObjectFell `$7FFE`. Then the cell under the new place: the player facing right (3) jumps to Crush `$9ABC`, the rest to MoveObjectLanded `$8104`. The cell below not empty: RollObject `$8117`.

Witness: L1 4511703 (c1, hiscore, lives, timer, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 22,233 calls, 3,034,408 t-states own (0.28 %) |
| Called from | `EarthFallGuard` (tail) |
| Calls | `Crush` (tail), `BoulderLandCheck` |
| Reads | `$FDD0`-`$FF41` (`CaveGrid+40`); `$FF56`-`$FF69` (`CaveGrid+430`); `$FF7D`-`$FFFE` (`CaveGrid+469`) |
| Writes | `$7FFE` (`ObjectFell`); `$FEAB`-`$FEAE` (`CaveGrid+259`); `$FEC9`-`$FECC` (`CaveGrid+289`); `$FF7F` (`CaveGrid+471`); `$FF9D` (`CaveGrid+501`) |

### `MoveObjectLanded` (`$8104`)

**The cell under the fallen object: the player facing left, or a switch box**

A = the cell. 4 jumps to Crush `$9ABC`; else LandOnSwitch `$810E`.

Witness: L1 15822 (c1, hiscore, rzx x32).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `LandOnSwitch` (`$810E`)

**A switch box under a fallen object sets SwitchHit**

A = `$0B`: SwitchHit `$7FFC` = `$FF`. The code that follows (`$8117`, RollObject) is reached from MoveObject when the cell below is not empty: an object on the player (3, 4), earth (6) or a vacated cell (`$20`) stays; else it rolls left when it is not in column 0 and the left cell and the one below it are both 0, else right when it is not in column 29 and those are 0.

Witness: L1 15805 (c1, hiscore, rzx x32).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `AntiGravSound` (`$8156`)

**The anti-gravity sound: falling BEEPER sweeps**

C = `$A0` down by 8 a sweep: periods from C + `$3C` down to C, 2 cycles each. Called by AntiGravStart `$A9EF`.

Witness: L1 16 (rzx x6).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 16 calls (`stage1/rzx11` 4, `stage1/rzx22` 4, `stage1/rzx03` 3 and 3 more) |

### `SwitchClear` (`$817A`)

**After a switch was hit: every force field and switch box becomes `$20`**

If SwitchHit `$7FFC`: every cell 9 (force field) and `$0B` (switch box) becomes `$20`, SwitchScore `$A9E3` (250 points and the sound), SwitchHit = 0. Then AntiGravPass `$A7CD`: the gravity scan of the pass.

Witness: L1 43776 (c1, hiscore, lives, timer, rzx x32).

[Animation: `SwitchClear` at work](img/routines/SwitchClear.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 265 calls, 16,643 t-states own (0.00 %) |
| Called from | `AnimateCellCodes` |
| Calls | `AntiGravPass` |
| Reads | `$7FFC` (`SwitchHit`) |

### `ClearVacated` (`$81AC`)

**Clear the vacated mark of every cell**

Every grid cell AND `$1F`: `$20` becomes 0, the animation codes `$10-$1F` stay.

Witness: L1 43775 (c1, hiscore, lives, timer, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 264 calls, 7,451,252 t-states own (0.68 %) |
| Called from | `PlayCave` |
| Reads | `$FDA8`-`$FFFF` (`CaveGrid`) |
| Writes | `$FDA8`-`$FF17` (`CaveGrid`); `$FF56`-`$FFFF` (`CaveGrid+430`) |

### `AnimateCellCodes` (`$937E`)

**SwitchClear, then every animation code steps on**

`$10-$14` step to `$15`, which becomes `$20` (the burst); `$15-$1B` step to `$1C`, which becomes `$20` (the dissolve).

Witness: L1 43776 (c1, hiscore, lives, timer, rzx x32).

[Animation: `AnimateCellCodes` at work](img/routines/AnimateCellCodes.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 265 calls, 9,236,453 t-states own (0.84 %) |
| Called from | `AbortKey` |
| Calls | `SwitchClear` |
| Reads | `$FDA8`-`$FFFF` (`CaveGrid`) |

### `EarthFallGuard` (`$9AA6`)

**Mark falling earth, then MoveObject**

Witness: L1 4511703 (c1, hiscore, lives, timer, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 22,233 calls, 1,995,664 t-states own (0.18 %) |
| Called from | `ScanCellsBody` |
| Calls | `MoveObject` (tail) |
| Reads | `$FDB2`-`$FDBB` (`CaveGrid+10`); `$FDDA`-`$FE2F` (`CaveGrid+50`); `$FE41`-`$FEB1` (`CaveGrid+153`); `$FEC3`-`$FEDE` (`CaveGrid+283`); `$FEF0`-`$FEF5` (`CaveGrid+328`); `$FF08`-`$FF23` (`CaveGrid+352`); 2 more ranges |
| Writes | `$9AA5` (`EarthFell`) |

### `Crush` (`$9ABC`)

**A falling object on the player: PlayerKilled unless it is earth**

Witness: L1 48 (c1, rzx x5): 47 falling earth in caves 13, 17, 22, 24, 26 (EarthFell set, no kill) and one boulder kill, c1 frame 13208 (CrushSkip once). The stage 2 recording death-crush kills the player at frame 21 (cave 1: up twice under a boulder, down once).

[Animation: `Crush` at work](img/routines/Crush.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 1 call, 80 t-states own (0.00 %) |
| Called from | `MoveObject` (tail) |
| Reads | `$9AA5` (`EarthFell`) |
| Writes | `$7FFD` (`PlayerKilled`) |

### `EarthAnim` (`$9DFC`)

**The falling-earth caves: animate earth and the empty cell (frames EmptyFrames `$FAE0`)**

Witness: L1 43775 (c1, hiscore, lives, timer, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 264 calls, 10,364 t-states own (0.00 %) |
| Called from | `AnimateTable` |
| Reads | `$800C`-`$800D` (`CellEarthGfx`) |

### `AntiGravScan` (`$A655`)

**The upward scan while anti-gravity runs: objects rise**

Witness: L1 1397 (rzx x6).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,397 calls (`stage1/rzx22` 396, `stage1/rzx11` 350, `stage1/rzx03` 297 and 3 more) |

### `AntiGravMove` (`$A6BB`)

**Move one object up**

Witness: L1 166974 (rzx x6).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 166,974 calls (`stage1/rzx22` 50,150, `stage1/rzx11` 32,782, `stage1/rzx03` 31,545 and 3 more) |

### `AntiGravStartScan` (`$A7A0`)

**Anti-gravity on: 99 steps, the digits, the icon**

Witness: L1 16 (rzx x6).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 16 calls (`stage1/rzx22` 4, `stage1/rzx11` 4, `stage1/rzx03` 3 and 3 more) |

### `AntiGravTake` (`$A7C7`)

**The player takes the arrow: AntiGravStartScan**

Witness: L1 15 (rzx x6).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 15 calls (`stage1/rzx11` 4, `stage1/rzx22` 3, `stage1/rzx03` 3 and 3 more) |

### `AntiGravPass` (`$A7CD`)

**The gravity scan of a pass: down, or up while anti-gravity runs**

Witness: L1 43776 (c1, hiscore, lives, timer, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 265 calls, 14,529 t-states own (0.00 %) |
| Called from | `SwitchClear` |
| Calls | `ScanCells` |
| Reads | `$FD8D` (`AntiGravSteps`) |

### `BoulderLandCheck` (`$E78C`)

**A boulder fell: BoulderLanded when the cell under its new place is not empty or vacated**

Witness: L1 9340 (c1, hiscore, rzx x29).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 2 calls, 320 t-states own (0.00 %) |
| Called from | `MoveObject` |
| Reads | `$FEE7` (`CaveGrid+319`); `$FFBB` (`CaveGrid+531`) |
| Writes | `$7FFF` (`BoulderFell`); `$E7A8` (`BoulderLanded`) |

### `ClearFallFlags` (`$E7F5`)

**BoulderLanded and BoulderFell = A, then ScanCellsBody**

Witness: L1 42379 (c1, hiscore, lives, timer, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 265 calls, 9,783 t-states own (0.00 %) |
| Called from | `ScanCells` (tail) |
| Calls | `ScanCellsBody` (tail) |
| Writes | `$7FFF` (`BoulderFell`); `$E7A8` (`BoulderLanded`) |

### `PassSound` (`$E83A`)

**The pass sound: a thud after a landing or a push, else the fall noise**

Witness: L1 43775 (c1, hiscore, lives, timer, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 264 calls, 20,056 t-states own (0.00 %) |
| Called from | `PassSoundJump` (tail) |
| Calls | `ThudSound`, `FallSoundChoice` (tail) |
| Reads | `$7FFF` (`BoulderFell`); `$E7A8` (`BoulderLanded`); `$E82E` (`BoulderPushed`) |

### `SetBoulderFlags` (`$E850`)

**BoulderFell and BoulderLanded = A**

Witness: L1 1397 (rzx x6).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,397 calls (`stage1/rzx22` 396, `stage1/rzx11` 350, `stage1/rzx03` 297 and 3 more) |

### `EarthAnimStep` (`$FB70`)

**The falling-earth caves' animation step**

Witness: L1 6610 (rzx x5).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 6,610 calls (`stage1/rzx26` 2,423, `stage1/rzx24` 1,611, `stage1/rzx22` 1,526 and 2 more) |

### `SetEarthFalls` (`$FB81`)

**Patch the scan so earth falls in the caves whose earth graphic is `$A4`xx**

The earth graphic's page decides the rule: earth falls when word 6 points into page `$A4` (GfxFallingEarth).

Witness: L1 47 (c1, hiscore, lives, timer, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 3 calls, 343 t-states own (0.00 %) |
| Called from | `ResetCave` |
| Calls | `CaveSetupAll` |
| Reads | `$800D` (`CellEarthGfx+1`) |
| Writes | `$8000`-`$8001` (`CellGraphicsTable`); `$809A` (`ScanEarthTest`); `$A67A` (`AntiGravEarthTest`) |

## renderer

`src/game/renderer.asm`

### `PrintGlyph` (`$8040`)

**Print an 8 x 8 glyph at a character cell**

B = the character row (0-23), C = the column (0-31), DE = the 8 glyph bytes. Out: DE past the glyph, HL the last screen byte. The font, the HUD digits and the map glyphs go through it.

Witness: L1 90104 (c1, hiscore, lives, menu, timer, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 1,110 calls, 440,188 t-states own (0.04 %) |
| Called from | `PrintDigits`, `PrintText` |
| Reads | `$BD00`-`$BD07` (`Font`); `$BD40`-`$BD4F` (`Font+64`); `$BD70`-`$BDB7` (`Font+112`, `DigitGlyphs`); `$BDC8`-`$BDD7` (`DigitGlyphs+72`); `$BDE8`-`$BDEF` (`DigitGlyphs+104`); `$BE08`-`$BECF` (`DigitGlyphs+136`); 1 more ranges |
| Writes | `$4000`-`$421F` (screen); `$42C5`-`$431F` (screen); `$43C5`-`$441F` (screen); `$44C5`-`$451F` (screen); `$45C5`-`$461F` (screen); `$46C5`-`$471F` (screen); 1 more ranges |

### `AttrAddr` (`$81B9`)

**The attribute address of character cell B, C into HL**

B = the row, C = the column. HL = `$5800` + 32B + C.

Witness: L1 3860 (c1, hiscore, lives, menu, timer, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 659 calls, 56,085 t-states own (0.01 %) |
| Called from | `FillAttrs` |

### `AttrAddrDE` (`$8265`)

**The attribute address of character cell B, C into DE**

B = the row, C = the column. DE = `$5800` + 32B + C.

Witness: L1 7714880 (c1, hiscore, lives, timer, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 46,640 calls, 3,834,085 t-states own (0.35 %) |
| Called from | `DrawCell` |

### `LineAddr` (`$8964`)

**The screen address of pixel line C, column 0, into HL**

Witness: L1 19296 (c1, lives, menu).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 10,720 calls, 951,401 t-states own (0.09 %) |
| Called from | `WipeInLogo`, `Pause` |

### `DrawPass` (`$8D46`)

**The colours and animations of a pass**

ColourCycleInk into the 4 attributes of the gem graphic `$9B74-$9B77` (ink, ink - 1, ink - 2, ink - 1), AnimateCells `$900B`, AnimateTable `$90B2`.

Witness: L1 43775 (c1, hiscore, lives, timer, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 264 calls, 34,600 t-states own (0.00 %) |
| Called from | `DrawWindowAtOrigin` |
| Calls | `AnimateCells`, `AnimateTable` |
| Reads | `$FD8F` (`ColourCycleInk`) |
| Writes | `$9B74`-`$9B77` (`GfxGem`) |

### `CellGraphicAddr` (`$8D66`)

**DE = the table word of cell A: `$8000` + 2 x (A AND `$1F`)**

Witness: L1 7714880 (c1, hiscore, lives, timer, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 46,640 calls, 1,609,973 t-states own (0.15 %) |
| Called from | `DrawCell` |

### `DrawWindowAtOrigin` (`$8D75`)

**Draw the window at ViewOrigin**

Witness: L1 43775 (c1, hiscore, lives, timer, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 264 calls, 5,314 t-states own (0.00 %) |
| Called from | `MapKey` |
| Calls | `DrawPass` |

### `DrawWindow` (`$8D78`)

**Draw 11 rows of 16 cells from cell index HL**

DrawCell `$8F60` for each; B = the character row (0, 2, ... 20), C = the column (0, 2, ... 30).

Witness: L1 44157 (c1, hiscore, lives, timer, rzx x32).

[Animation: `DrawWindow` at work](img/routines/DrawWindow.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 1 call, 8,681,448 t-states own (0.79 %) |
| Called from | `DeathView` |
| Calls | `DrawCell` |
| Reads | `$FE26`-`$FFFF` (`CaveGrid+126`) |

### `WindowOrigin` (`$8DA6`)

**The window's first cell from the player's place**

Row = PlayerIndex / 30, column the rest; the column clamped to 8-22, the row to 5-14; ViewOrigin `$FD70` = 30 x (row - 5) + column - 8 (computed as 30 x (row + 1) + column - 188). The window is drawn later, by MapKey's CALL DrawWindowAtOrigin.

Witness: L1 43833 (c1, hiscore, lives, timer, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 264 calls, 209,015 t-states own (0.02 %) |
| Called from | `PlayCave` |
| Reads | `$FD9C`-`$FD9D` (`PlayerIndex`) |
| Writes | `$FD70`-`$FD71` (`ViewOrigin`) |

### `DrawCell` (`$8F60`)

**Draw cell code A at character row B, column C (2 x 2 characters)**

The graphic from CellGraphicsTable; its 4 attributes through AttrAddrDE `$8265`, then 32 pixel bytes in zigzag order. Valid on even character rows: SET 5,E for the lower half needs bit 5 of E clear. The graphic pointer steps with INC L inside each 4-byte group, so no group may cross a 256-byte page.

Witness: L1 7714880 (c1, hiscore, lives, timer, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 46,640 calls, 45,101,285 t-states own (4.12 %) |
| Called from | `DrawWindow` |
| Calls | `AttrAddrDE`, `CellGraphicAddr` |
| Reads | `$8000`-`$801F` (`CellGraphicsTable`, `CellExitGfx`, `CellBoulderGfx`, `CellPlayerRightGfx` and 12 more); `$9B2C`-`$9CDB` (`GfxBoulder`, `GfxEarth`, `GfxGem`, `GfxPlayerRight` and 2 more); `$9DB4`-`$9DD7` (`GfxDeathRight`); `$9ED4`-`$9F63` (`GfxFire`); `$A114`-`$A1A3` (`GfxBubble`); `$A4E0`-`$A56F` (`GfxJellyBean`); 1 more ranges |
| Writes | `$4000`-`$50BF` (screen); `$5100`-`$51BF` (screen); `$5200`-`$52BF` (screen); `$5300`-`$53BF` (screen); `$5400`-`$54BF` (screen); `$5500`-`$55BF` (screen); 3 more ranges |

### `AnimateCells` (`$900B`)

**Step the player and exit frames (4 frames, 36 bytes apart)**

AnimPhase `$FD72` 0-3: the player's table words `$8006` / `$8008` from `$9B98` / `$9C28` + 36 x phase. Out: HL = ViewOrigin.

Witness: L1 43775 (c1, hiscore, lives, timer, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 264 calls, 43,327 t-states own (0.00 %) |
| Called from | `DrawPass` |
| Reads | `$8006`-`$8009` (`CellPlayerRightGfx`, `CellPlayerLeftGfx`); `$FD70`-`$FD72` (`ViewOrigin`, `AnimPhase`) |
| Writes | `$8006`-`$8009` (`CellPlayerRightGfx`, `CellPlayerLeftGfx`); `$FD72` (`AnimPhase`) |

### `AnimateTable` (`$90B2`)

**Step the animated table words of the specials**

EarthAnim `$9DFC`, then the words of cells 8, 9, `$0A`, `$0C`, `$0D`, `$0E`, `$0F` from frame AnimPhase.

Witness: L1 43775 (c1, hiscore, lives, timer, rzx x32).

[Animation: `AnimateTable` at work](img/routines/AnimateTable.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 264 calls, 257,953 t-states own (0.02 %) |
| Called from | `DrawPass` |
| Calls | `EarthAnim` |
| Reads | `$FD72`-`$FD74` (`AnimPhase`, `ForceFieldPhase`, `TeleporterPhase`) |
| Writes | `$8010`-`$801F` (`CellJellyBeanGfx`, `CellForceFieldGfx`, `CellAntiGravGfx`, `CellSwitchGfx` and 4 more); `$FD73`-`$FD74` (`ForceFieldPhase`, `TeleporterPhase`) |

## mapscreen

`src/game/mapscreen.asm`

### `DrawMapCells` (`$8059`)

**Draw the 600 cells as 8 x 8 glyphs, from the last cell back**

HL = the grid's last cell `$FFFF`, B = 20 rows, C = 30 columns, D = `$9A` (LD D,`$9A` at `$8060`); a cell of code k is the glyph MapGlyphs + 8k, printed by MapCellGlyph `$E9AE` at row B, column C.

Witness: L1 1 (timer).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/timer` 1) |

### `DrawMapCellsLoop` (`$8061`)

**The per-cell body of DrawMapCells (entered at SBC A,D)**

E = 8 x the cell, MapCellGlyph `$E9AE`; HL, C and B step down; the row loop DJNZ goes back to `$805E`.

Witness: L1 580 (timer).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ColourMapCells` (`$81CC`)

**Colour the map: each cell's attribute from MapAttrs + its code**

From the last cell back, 20 rows of 30; MapCellAttr `$EAB3` writes the attribute (cells from `$90` get 0).

Witness: L1 1 (timer).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/timer` 1) |

### `PlayMapTune` (`$E8E1`)

**Play MapTune**

Witness: L1 1 (timer).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/timer` 1) |

### `MapCellGlyph` (`$E9AE`)

**Print the map glyph of a cell below `$80`**

Witness: L1 600 (timer).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 600 calls (`stage1/timer` 600) |

### `DrawMapFrame` (`$EA00`)

**Draw the map's frame**

Witness: L1 1 (timer).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/timer` 1) |

### `ShowMap` (`$EA80`)

**The map screen**

Witness: L1 1 (timer).

[Animation: `ShowMap` at work](img/routines/ShowMap.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/timer` 1) |

### `ClearMapFlag` (`$EA8E`)

**MapShown and PlayerKilled 0**

Witness: L1 47 (c1, hiscore, lives, timer, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 3 calls, 120 t-states own (0.00 %) |
| Called from | `CaveInit` |
| Writes | `$7FFD` (`PlayerKilled`); `$EA8D` (`MapShown`) |

### `MapKey` (`$EA96`)

**Key F: the map, once per cave**

Its last instruction, CALL DrawWindowAtOrigin `$8D75`, runs every pass: this is where the window is drawn.

Witness: L1 43775 (c1, hiscore, lives, timer, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 264 calls, 21,476 t-states own (0.00 %) |
| Called from | `PlayCave` |
| Calls | `DrawWindowAtOrigin` |
| Ports in | `$FDFE` |
| Ports out | `$FDFF` |

### `MapCellAttr` (`$EAB3`)

**The map attribute of a cell, 0 for cells from `$90`**

Witness: L1 600 (timer).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 600 calls (`stage1/timer` 600) |

## main

`src/game/main.asm`

### `ColourCycle` (`$81E7`)

**Step the cycling colour and flash the open exit**

ColourPhase `$FD8E` steps; ColourCycleInk `$FD8F` cycles `$43-$46` (DrawPass `$8D46` writes it into the gem graphic). Ends with CALL ExitFlash `$905B`, RET (on either branch).

Witness: L1 43775 (c1, hiscore, lives, timer, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 264 calls, 37,076 t-states own (0.00 %) |
| Called from | `PlayCave` |
| Calls | `ExitFlash` |
| Reads | `$FD8E`-`$FD8F` (`ColourPhase`, `ColourCycleInk`) |
| Writes | `$FD8E`-`$FD8F` (`ColourPhase`, `ColourCycleInk`) |

### `ClearVars` (`$821A`)

**Clear the variables and the cave grid, `$FD7A-$FFFF`**

HL = `$FD7A`, DE = HL + 1, BC = `$028A`, (HL) = 0, LDIR: the copy runs on past `$FFFF` into `$0000-$0004` (the ROM: no effect).

Witness: L1 9 (c1, lives, menu).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 5 calls, 68,497 t-states own (0.01 %) |
| Called from | `ResetAll` |
| Reads | `$FD7A`-`$FFFF` (`ClearStart`, `VarsFD7B`, `TimerSub`, `CaveOver` and 29 more) |
| Writes | `$FD7A`-`$FF17` (`ClearStart`, `VarsFD7B`, `TimerSub`, `CaveOver` and 29 more); `$FF56`-`$FFFF` (`CaveGrid+430`) |

### `ResetGame` (`$82E6`)

**The first cave, 4 lives, the colour phase**

ColourPhase `$FD8E` = 1, CaveNumber `$FD91` = 1, Lives `$FD93` = 4, Unused99 `$FD90` = 99. StartGame `$85D6` sets 5 lives later.

Witness: L1 9 (c1, lives, menu).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 5 calls, 431 t-states own (0.00 %) |
| Called from | `ResetAll` |
| Writes | `$FD8E`-`$FD93` (`ColourPhase`, `ColourCycleInk`, `Unused99`, `CaveNumber` and 2 more) |

### `ResetCave` (`$85F1`)

**Clear the cave's state and print the HUD**

CaveDone, ExitOpen and GemDigits 0, GemCount 0; SetEarthFalls `$FB81`, FaceLeft, ShowHudLine, ShowScore, ShowCounters.

Witness: L1 47 (c1, hiscore, lives, timer, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 3 calls, 542 t-states own (0.00 %) |
| Called from | `CaveReset` |
| Calls | `ShowScore`, `ShowHudLine`, `FaceLeft`, `ShowCounters`, `SetEarthFalls` |
| Writes | `$FD82`-`$FD92` (`GemDigits`, `CaveDone`, `ExitOpen`, `PlayerFacing` and 9 more) |

### `CaveReset` (`$8687`)

**Reset the anti-gravity and the cave state, fill the time bar**

ResetAntiGrav `$A64B`, ResetCave `$85F1`, FillTimeBar `$8654`.

Witness: L1 47 (c1, hiscore, lives, timer, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 3 calls, 204 t-states own (0.00 %) |
| Called from | `CaveStartState` |
| Calls | `ResetCave`, `FillTimeBar`, `ResetAntiGrav` |

### `ShiftTimeBar` (`$8691`)

**Shift the time bar one pixel left**

8 pixel lines from `$50DF`: RL through the 32 bytes of a line, the rightmost first. The bar's first byte `$52C0` empties last.

Witness: L1 15903 (c1, hiscore, lives, timer, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 283 calls, 2,816,051 t-states own (0.26 %) |
| Called from | `TimerStep`, `QuitKey` |
| Reads | `$50C0`-`$50DF` (screen); `$51C0`-`$51DF` (screen); `$52C0`-`$52DF` (screen); `$53C0`-`$53DF` (screen); `$54C0`-`$54DF` (screen); `$55C0`-`$55DF` (screen); 2 more ranges |
| Writes | `$50C0`-`$51DF` (screen); `$52C0`-`$52DF` (screen); `$53C0`-`$53DF` (screen); `$54C0`-`$54DF` (screen); `$55C0`-`$55DF` (screen); `$56C0`-`$56DF` (screen); 1 more ranges |

### `TimeOutSound` (`$86AD`)

**The time-out sound: a falling sweep**

LD C,(HL) then AND `$7F`: the AND acts on A, so C keeps the full ROM byte (a 0 byte gives a 256-turn low half).

Witness: L1 13 (c1, hiscore, lives, timer).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 1 call, 3,657,389 t-states own (0.33 %) |
| Called from | `QuitKey` |
| Ports out | `$00FE`, `$18FE` |

### `TimerStep` (`$86DE`)

**The timer: every fourth pass the bar loses a pixel; an empty bar ends the cave**

TimerSub `$FD7C` + `$40`; on the wrap: ShiftTimeBar `$8691` and a ROM BEEPER click (HL = 0, DE = 0). The bar's first byte `$52C0` at 0: TimeOutSound `$86AD`, CaveOver `$FD7D` = `$FF`.

Witness: L1 43907 (c1, hiscore, lives, timer, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 264 calls, 18,494 t-states own (0.00 %) |
| Called from | `PlayCave` |
| Calls | `ShiftTimeBar` |
| Reads | `$52C0` (screen); `$FD7C` (`TimerSub`) |
| Writes | `$FD7C` (`TimerSub`) |

### `TimeBonus` (`$8702`)

**The cave done: every remaining bar pixel is a point**

DI at its start, but the first BEEPER's EI turns them on again: 41 of the 45 interrupts in the bonus are taken (rzx-earth01 3668-3713). While `$52C0` is not 0: BonusTick `$871C` (a beep, D its period, rising), ShiftTimeBar, AddPoint, ShowScore.

Witness: L1 32 (rzx x32).

[Animation: `TimeBonus` at work](img/routines/TimeBonus.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 32 calls (`stage1/rzx17` 1, `stage1/rzx28` 1, `stage1/rzx25` 1 and 29 more) |

### `BonusTick` (`$871C`)

**One bonus beep: ROM BEEPER HL = D, DE = 1; its three DEC D are lost to TimeBonus's POP DE, so D falls by 1 a pixel (TimeBonus's own DEC D)**

Witness: L1 2062 (rzx x32).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 2,062 calls (`stage1/rzx17` 212, `stage1/rzx28` 202, `stage1/rzx25` 195 and 29 more) |

### `QuitKey` (`$872D`)

**Key H (half row `$BF`, bit 4): drain the time bar, end the cave**

Shifts the bar with a click until it is empty, then CaveOver `$FD7D` = `$FF` and TimeOutSound: NextCave takes a life. The DI at `$8736` lasts only to the first BEEPER (its EI): the drain runs with interrupts on. About 10 650 T a pixel (L1 totals of lives and c1), a full bar about 39 frames.

Witness: L1 43775 (c1, hiscore, lives, timer, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 264 calls, 41,891 t-states own (0.00 %) |
| Called from | `PlayCave` |
| Calls | `ShiftTimeBar`, `TimeOutSound` |
| Reads | `$52C0` (screen) |
| Writes | `$FD7D` (`CaveOver`) |
| Ports in | `$BFFE` |
| Ports out | `$BFFF` |

### `PlayCave` (`$8885`)

**Play a cave: passes until out of time, killed or done**

CaveOver `$FD7D` = 0, CaveInit `$91B9`; each pass KeyMoved `$FD80` = 0, then the steps of the module header. CaveOver ends it; PlayerKilled: DeathView `$903F`, DeathSound `$862E`; CaveDone: TimeBonus `$8702`.

Witness: L1 47 (c1, hiscore, lives, timer, rzx x32).

[Animation: `PlayCave` at work](img/routines/PlayCave.gif)

[Animation: `PlayCave` at work, cave13](img/routines/PlayCave-cave13.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 3 calls, 81,415 t-states own (0.01 %) |
| Called from | `CavePlay` |
| Calls | `ClearVacated`, `ColourCycle`, `PutPlayer`, `DeathSound`, `TimerStep`, `QuitKey`, `KeysStep`, `WindowOrigin`, `DeathView`, `CaveInit`, `AbortKey`, `FizzSound`, `MapKey` |
| Reads | `$7FFD` (`PlayerKilled`); `$FD7D`-`$FD84` (`CaveOver`, `CaveDigits`, `KeyMoved`, `VarsFD81` and 2 more) |
| Writes | `$FD7D`-`$FD80` (`CaveOver`, `CaveDigits`, `KeyMoved`) |

### `CavePlay` (`$89EA`)

**The cave's intro, its tune and its play**

CaveIntro `$92D4`, PlayCaveTuneJump `$895D`, PlayCave `$8885` (`$89F0`).

Witness: L1 46 (c1, hiscore, lives, timer, rzx x31).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 3 calls, 201 t-states own (0.00 %) |
| Called from | `StartGameEntry` |
| Calls | `PlayCave`, `PlayCaveTuneJump`, `CaveIntro` |

### `StartGameEntry` (`$89F4`)

**A game: StartGame, then the caves**

Witness: L1 3 (c1, lives, rzx x1).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 1 call, 408 t-states own (0.00 %) |
| Called from | `NewGame` |
| Calls | `StartGame`, `ClearScreen`, `CavePlay` |
| Reads | `$FD84`-`$FD93` (`CaveDone`, `ExitOpen`, `PlayerFacing`, `Continuation` and 9 more) |
| Writes | `$7FFD` (`PlayerKilled`); `$FD7D`-`$FD93` (`CaveOver`, `CaveDigits`, `KeyMoved`, `VarsFD81` and 14 more) |

### `CaveStart` (`$89F7`)

**Start a cave: clear the screen and the flags, play it**

ClearScreen `$860E`, PlayerKilled, CaveOver and CaveDone 0, CavePlay `$89EA`; then NextCave.

Witness: L1 46 (c1, hiscore, lives, timer, rzx x31).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 33 calls (`stage1/rzx07` 1, `stage1/rzx06` 1, `stage1/rzx08` 1 and 31 more) |

### `NextCave` (`$8A07`)

**After a cave: the next one, or a life lost**

CaveDone: the cave digits + 1, CaveNumber + 1; after 32 (CaveNumber `$21`) WinGame `$A8BF` and cave 1. Not done: Lives - 1; at 0 the game ends (RET), else the same cave again.

Witness: L1 46 (c1, hiscore, lives, timer, rzx x32).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rzx08`, `stage1/rzx16`, `stage1/rzx18` and 31 more) |

### `NewGame` (`$8BE5`)

**Key 1: a game, then the high-score check**

StartGameEntry `$89F4`, then GameOver `$7FF3` (`$8BE8`).

Witness: L1 3 (c1, lives, rzx x1).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 1 call, 17 t-states own (0.00 %) |
| Called from | `GameEntry` |
| Calls | `StartGameEntry` |

### `DeathView` (`$903F`)

**The killed player: the death graphics in the player's table words, the window redrawn**

`$8006` = `$9DB4`, `$8008` = `$9DD8`, DrawWindow at ViewOrigin.

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 1 call, 101 t-states own (0.00 %) |
| Called from | `PlayCave` |
| Calls | `DrawWindow` |
| Reads | `$FD70`-`$FD71` (`ViewOrigin`) |
| Writes | `$8006`-`$8009` (`CellPlayerRightGfx`, `CellPlayerLeftGfx`) |

### `CaveStartState` (`$9052`)

**AnimPhase = 3, CaveReset**

Witness: L1 47 (c1, hiscore, lives, timer, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 3 calls, 153 t-states own (0.00 %) |
| Called from | `CaveInit` |
| Calls | `CaveReset` |
| Writes | `$FD72` (`AnimPhase`) |

### `ExitFlash` (`$905B`)

**Flash the exit door's colour while the exit is open**

Witness: L1 43775 (c1, hiscore, lives, timer, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 264 calls, 8,079 t-states own (0.00 %) |
| Called from | `ColourCycle` |
| Reads | `$FD85` (`ExitOpen`) |

### `CaveInit` (`$91B9`)

**A cave's start: CaveStartState, MapShown and PlayerKilled 0**

Witness: L1 47 (c1, hiscore, lives, timer, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 3 calls, 169 t-states own (0.00 %) |
| Called from | `PlayCave` |
| Calls | `CaveStartState`, `ClearMapFlag` |

### `CaveIntro` (`$92D4`)

**The cave's intro screen: level, lives, score, the cave name centred on row 20**

Witness: L1 46 (c1, hiscore, lives, timer, rzx x31).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 3 calls, 812 t-states own (0.00 %) |
| Called from | `CavePlay` |
| Calls | `PrintText`, `ColourLevelLivesScore` |
| Reads | `$9713` (`CaveNames+19`); `$FD91` (`CaveNumber`) |

### `AbortKey` (`$93A5`)

**Key G (half row `$FD`, bit 4): back to the menu, the return addresses dropped**

The four POPs drop the returns of PlayCave, CavePlay, CaveStart and NewGame (`$889B`, `$89F3`, `$8A07`, `$8BE8`, the CALL GameOver); the RET reaches `$8B42` (JP GameEntry): no game-over screen, no high-score check. Witness: c1, AbortKey last at 15 244, GameOver never runs.

Witness: L1 43776 (c1, hiscore, lives, timer, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 265 calls, 18,867 t-states own (0.00 %) |
| Called from | `PlayCave` |
| Calls | `AnimateCellCodes` |
| Ports in | `$FDFE` |
| Ports out | `$FDFF` |

### `PlayWinTune` (`$A615`)

**Play WinTune `$6EF4`**

Witness: L1 1 (rzx x1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/rzx32` 1) |

### `PlayWinTuneEnd` (`$A61B`)

**RET after the win tune**

Known only from the code: the rzx32 recording ends during the tune.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `WinScreen` (`$A61C`)

**Clear the screen, draw three cells (the player and two gems)**

Witness: L1 1 (rzx x1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/rzx32` 1) |

### `ResetAntiGrav` (`$A64B`)

**ResetAntiGravState, FizzCount and SwitchHit 0**

Witness: L1 47 (c1, hiscore, lives, timer, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 3 calls, 159 t-states own (0.00 %) |
| Called from | `CaveReset` |
| Calls | `ResetAntiGravState` |
| Writes | `$7FFB`-`$7FFC` (`FizzCount`, `SwitchHit`) |

### `ResetAntiGravState` (`$A792`)

**ClearScreenCave, the anti-gravity digits and steps 0**

Witness: L1 47 (c1, hiscore, lives, timer, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 3 calls, 232 t-states own (0.00 %) |
| Called from | `ResetAntiGrav` |
| Calls | `ClearScreenCave` |
| Writes | `$FD8B`-`$FD8D` (`AntiGravDigits`, `AntiGravSteps`) |

### `ShowWinTexts` (`$A815`)

**Print WinTexts `$AB6A`**

Witness: L1 1 (rzx x1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/rzx32` 1) |

### `ColourWinTexts` (`$A86E`)

**Colour the win texts**

Witness: L1 1 (rzx x1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/rzx32` 1) |

### `WinGame` (`$A8BF`)

**After cave 32: the win screen and tune**

Witness: L1 1 (rzx x1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/rzx32` 1) |

## unpack

`src/game/unpack.asm`

### `UnpackCave` (`$82B6`)

**Unpack cave CaveNumber into the grid and copy its 14 parameters**

HL = `$BEC6` + 314 x CaveNumber `$FD91`; 300 bytes give 600 cells (low nibble first) into CaveGrid `$FDA8`, then 14 bytes to CaveParams `$FD9A`.

Witness: L1 47 (c1, hiscore, lives, timer, rzx x32).

[Animation: `UnpackCave` at work](img/routines/UnpackCave.gif)

[Animation: `UnpackCave` at work, memory](img/routines/UnpackCave-memory.gif)

[Animation: `UnpackCave` at work, nibbles](img/routines/UnpackCave-nibbles.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 3 calls, 92,996 t-states own (0.01 %) |
| Called from | `CaveSetup` |
| Reads | `$C000`-`$C139` (`CaveData`); `$FD91` (`CaveNumber`) |
| Writes | `$FD9A`-`$FF17` (`CaveParams`, `GemValue`, `PlayerIndex`, `GemsNeededDigits` and 7 more); `$FF56`-`$FFFF` (`CaveGrid+430`) |

### `SetGraphicColour` (`$9305`)

**Write A into the 4 attributes of the graphic at HL: bright, plain, plain, bright**

Witness: L1 517 (c1, hiscore, lives, timer, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 33 calls, 2,679 t-states own (0.00 %) |
| Called from | `CaveSetup`, `CaveSetupAll` |
| Writes | `$9B08`-`$9B53` (`CellGraphics`, `GfxBoulder`, `GfxEarth`); `$9CB8`-`$9CBB` (`GfxWall1`); `$A1A4`-`$A1CB` (`GfxDissolve`); `$A1EC`-`$A1EF` (`GfxDissolve+72`); `$A210`-`$A213` (`GfxDissolve+108`); `$A234`-`$A237` (`GfxDissolve+144`); 2 more ranges |

### `CaveSetup` (`$9313`)

**Unpack the cave; its earth and wall graphics and its four colours**

UnpackCave `$82B6`; EarthGraphic `$FDA0` into the table word `$800C` (cell 6), WallGraphic `$FDA2` into `$800A` (cell 5); DoorColour into the exit graphic `$9B08`, BoulderColour into `$9B2C`, Wall1Colour into `$9CB8`, EarthColour into `$9B50` (SetGraphicColour).

Witness: L1 47 (c1, hiscore, lives, timer, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 3 calls, 884 t-states own (0.00 %) |
| Called from | `CaveSetupAll` |
| Calls | `UnpackCave`, `SetGraphicColour` |
| Reads | `$FDA0`-`$FDA7` (`EarthGraphic`, `WallGraphic`, `DoorColour`, `BoulderColour` and 2 more) |
| Writes | `$800A`-`$800D` (`CellWallGfx`, `CellEarthGfx`) |

### `ClearScreenCave` (`$9346`)

**ClearScreen, ColourCycleInk = `$45`**

Witness: L1 47 (c1, hiscore, lives, timer, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 3 calls, 175 t-states own (0.00 %) |
| Called from | `ResetAntiGravState` |
| Calls | `ClearScreen` |
| Writes | `$FD8F` (`ColourCycleInk`) |

### `CaveSetupAll` (`$A600`)

**CaveSetup, then the boulder colour into the 7 dissolve frames**

Witness: L1 47 (c1, hiscore, lives, timer, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 3 calls, 1,157 t-states own (0.00 %) |
| Called from | `SetEarthFalls` |
| Calls | `SetGraphicColour`, `CaveSetup` |
| Reads | `$9B2C` (`GfxBoulder`) |

## hud

`src/game/hud.asm`

### `IncDigits` (`$8315`)

**Add 1 to a decimal digit string**

HL = the last digit, B = the digits. The carry runs left while a digit wraps from 9 to 0.

Witness: L1 70659 (c1, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 22 calls, 926 t-states own (0.00 %) |
| Called from | `AddPoint`, `CountGem` |
| Reads | `$FD83` (`GemDigits+1`); `$FD98`-`$FD99` (`ScoreDigits+4`) |
| Writes | `$FD83` (`GemDigits+1`); `$FD98`-`$FD99` (`ScoreDigits+4`) |

### `AddPoint` (`$8321`)

**Add 1 point to the score**

IncDigits on ScoreDigits `$FD94-$FD99`.

Witness: L1 61961 (c1, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 20 calls, 937 t-states own (0.00 %) |
| Called from | `AddGemValue` |
| Calls | `IncDigits` |

### `PrintDigits` (`$832A`)

**Print D decimal digits right to left**

HL = the last digit, B = the row, C = the last digit's column, D = the count. The glyph of digit k is `$BD80` + 8k.

Witness: L1 82125 (c1, hiscore, lives, menu, timer, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 25 calls, 12,539 t-states own (0.00 %) |
| Called from | `ShowScore`, `CountGem`, `ShowCounters`, `ShowLevelLivesScore` |
| Calls | `PrintGlyph` |
| Reads | `$FD7E`-`$FD9F` (`CaveDigits`, `KeyMoved`, `VarsFD81`, `GemDigits` and 18 more) |

### `ShowScore` (`$8342`)

**Print the score at row 23, columns 26-31**

Witness: L1 12605 (c1, hiscore, lives, timer, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 5 calls, 312 t-states own (0.00 %) |
| Called from | `CollectGem`, `ResetCave` |
| Calls | `PrintDigits` |

### `PrintText` (`$834F`)

**Print D characters of ASCII text**

HL = the text, B = the row, C = the first column, D = the length. The glyph of code k is `$BC00` + 8k (Font `$BD00` is code `$20`).

Witness: L1 5949 (c1, hiscore, lives, menu, timer, rzx x32).

[Animation: `PrintText` at work](img/routines/PrintText.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 56 calls, 1,706,987 t-states own (0.16 %) |
| Called from | `ShowHudLine`, `ShowLevelLivesScore`, `ShowMenuTexts`, `RedefineKeys`, `ShowPasswordPrompt`, `CaveIntro`, `ShowControlTexts` |
| Calls | `PrintGlyph` |
| Reads | `$9700`-`$9713` (`CaveNames`); `$9AE8`-`$9B07` (`EnterPasswordText`); `$A91D`-`$A92C` (`KeyTable+29`); `$A956`-`$A9D6` (`KeyTable+86`, `KeyPrompts`); `$AB00`-`$AB68` (`MenuTexts`, `MenuRedefineText`, `MenuDemoText`, `MenuQuitText` and 1 more); `$BB00`-`$BB15` (`HudLabels`, `LivesLeftText`, `ScoreText`); 2 more ranges |

### `ShowHudLine` (`$836A`)

**Print HudLine `$BCE0` on row 23**

Witness: L1 47 (c1, hiscore, lives, timer, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 3 calls, 180 t-states own (0.00 %) |
| Called from | `ResetCave` |
| Calls | `PrintText` |

### `AddGemValue` (`$8376`)

**Add GemValue `$FD9B` points, one at a time**

Witness: L1 1692 (c1, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 2 calls, 1,188 t-states own (0.00 %) |
| Called from | `CollectGem` |
| Calls | `AddPoint` |
| Reads | `$FD9B` (`GemValue`) |

### `PutPlayer` (`$8382`)

**Write the player's code at the player's cell**

CaveGrid + PlayerIndex = PlayerFacing `$FD86`.

Witness: L1 43776 (c1, hiscore, lives, timer, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 265 calls, 18,319 t-states own (0.00 %) |
| Called from | `PlayCave` |
| Reads | `$FD86` (`PlayerFacing`); `$FD9C`-`$FD9D` (`PlayerIndex`) |
| Writes | `$FEC4`-`$FECC` (`CaveGrid+284`); `$FEE2`-`$FEEA` (`CaveGrid+314`); `$FF00`-`$FF01` (`CaveGrid+344`); `$FF5A`-`$FF63` (`CaveGrid+434`); `$FF79` (`CaveGrid+465`); `$FF97`-`$FF9E` (`CaveGrid+495`) |

### `FaceLeft` (`$838E`)

**PlayerFacing = 4 (facing left)**

Witness: L1 47 (c1, hiscore, lives, timer, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 3 calls, 120 t-states own (0.00 %) |
| Called from | `ResetCave` |
| Writes | `$FD86` (`PlayerFacing`) |

### `CountGem` (`$8394`)

**Count a gem; open the exit when enough are taken**

GemCount `$FD92` + 1; when it equals GemsNeeded `$FD9A`, ExitOpen `$FD85` = `$FF`. Then GemDigits `$FD82` + 1 (IncDigits `$8315`: the gems taken, counting up from 00), printed at row 23 (PrintDigits, BC = `$1709`), and GemSound `$82F9`.

Witness: rzx-earth01 frame 814, the panel goes from 00 to 01.

Witness: L1 1692 (c1, rzx x32).

[Animation: `CountGem` at work](img/routines/CountGem.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 2 calls, 398 t-states own (0.00 %) |
| Called from | `CollectGem` |
| Calls | `GemSound`, `IncDigits`, `PrintDigits` |
| Reads | `$FD92`-`$FD9A` (`GemCount`, `Lives`, `ScoreDigits`, `CaveParams`) |
| Writes | `$FD92` (`GemCount`) |

### `ShowCounters` (`$85AD`)

**Print the cave number, the gems needed and the lives on row 23**

Witness: L1 53 (c1, hiscore, lives, timer, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 3 calls, 454 t-states own (0.00 %) |
| Called from | `ResetCave` |
| Calls | `PrintDigits` |

### `FillTimeBar` (`$8654`)

**Fill the time bar (4 pixel lines of 32 bytes `$FF` from `$52C0`) and colour it**

Then BarColours `$9224`.

4 pixel lines of 32 bytes from `$52C0`: 256 pixels, one taken every 4th pass by TimerStep, so a cave lasts 1024 passes (the timer recording: 5543 frames of passes, 5.41 frames a pass).

Witness: L1 47 (c1, hiscore, lives, timer, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 3 calls, 12,768 t-states own (0.00 %) |
| Called from | `CaveReset` |
| Calls | `BarColours` |
| Reads | `$52C0`-`$52DE` (screen); `$53C0`-`$53DE` (screen); `$54C0`-`$54DE` (screen); `$55C0`-`$55DE` (screen) |
| Writes | `$52C0`-`$52DF` (screen); `$53C0`-`$53DF` (screen); `$54C0`-`$54DF` (screen); `$55C0`-`$55DF` (screen) |

### `ShowLevelLivesScore` (`$89A7`)

**Print LEVEL, LIVES LEFT: and SCORE: with their values**

HudLabels `$BB00` and the digits, for CaveIntro `$92D4`.

Witness: L1 46 (c1, hiscore, lives, timer, rzx x31).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 3 calls, 856 t-states own (0.00 %) |
| Called from | `ColourLevelLivesScore` |
| Calls | `PrintDigits`, `PrintText` |

### `ColourLevelLivesScore` (`$8BEC`)

**Colour and print the cave intro's three lines**

Witness: L1 46 (c1, hiscore, lives, timer, rzx x31).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 3 calls, 469 t-states own (0.00 %) |
| Called from | `CaveIntro` |
| Calls | `ShowLevelLivesScore`, `FillAttrs` |

### `JellyBean` (`$91F7`)

**The jelly bean (8): 32 pixels added to the time bar with a sweep, 64 points**

Witness: L1 132 (rzx x23).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 132 calls (`stage1/rzx32` 20, `stage1/rzx26` 17, `stage1/rzx29` 11 and 20 more) |

### `BarColours` (`$9224`)

**Colour the time bar from BarAttrs `$BC92`**

Witness: L1 105 (c1, hiscore, lives, timer, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 3 calls, 5,550 t-states own (0.00 %) |
| Called from | `FillTimeBar` |
| Reads | `$BC92`-`$BCD1` (`BarAttrs`) |
| Writes | `$5AC0`-`$5AFF` (screen) |

### `AddPoints` (`$A8D5`)

**Add B points**

Witness: L1 31019 (rzx x29).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 4,405 calls (`stage1/rzx32` 662, `stage1/rzx26` 546, `stage1/rzx29` 364 and 26 more) |

### `PotionScore` (`$A8E0`)

**20 points**

The PUSH BC at `$A8E3` is never popped: the RET pops it. BC is `$0038` after PotionTune, so the RET jumps to the ROM's IM 1 routine at `$0038`, which scans the keyboard and RETs to the true return `$91DA` in TakePotion. Witness: rzx-earth09 frame 6397 (`$A8F1` at T 67102, `$0038` at 67112, `$91DA` at 67994).

Witness: L1 6 (rzx x6).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 6 calls (`stage1/rzx15` 1, `stage1/rzx19` 1, `stage1/rzx22` 1 and 3 more) |

### `TimeRefill` (`$A9D7`)

**Refill the time bar: 32 steps, 2 points each**

Witness: L1 4224 (rzx x23).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 4,224 calls (`stage1/rzx32` 640, `stage1/rzx26` 544, `stage1/rzx29` 352 and 20 more) |

### `SwitchScore` (`$A9E3`)

**The switch: 250 points and its sound**

Witness: L1 23 (rzx x23).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 23 calls (`stage1/rzx26` 1, `stage1/rzx07` 1, `stage1/rzx24` 1 and 20 more) |

### `AntiGravStart` (`$A9EF`)

**The arrow taken: the sound, 200 points**

Witness: L1 16 (rzx x6).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 16 calls (`stage1/rzx22` 4, `stage1/rzx11` 4, `stage1/rzx03` 3 and 3 more) |

## player

`src/game/player.asm`

### `TryLeft` (`$83C3`)

**The left key: move or act to the left**

The key site LD A,row (`$83C4`) / AND mask (`$83CA`) is written by RedefineKeys `$8C30` and the control choice. Pressed: PlayerFacing = 4, KeyMoved = `$FF`; column 0 stops; the exit (1) only when ExitOpen (then CaveDone); the wall test BlockWall `$E869`, boulders PushBoulder `$E81F`, the codes > 6 LeftSpecial `$94D6` (which takes gems and the other specials, continuation MoveLeft); then MoveLeft `$8428`.

Witness: L1 42086 (c1, hiscore, lives, timer, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 265 calls, 25,032 t-states own (0.00 %) |
| Called from | `PlayerStep` |
| Calls | `PushBoulder`, `BlockWall` |
| Reads | `$FD9C`-`$FD9D` (`PlayerIndex`); `$FEC3`-`$FEC4` (`CaveGrid+283`) |
| Writes | `$FD80`-`$FD86` (`KeyMoved`, `VarsFD81`, `GemDigits`, `CaveDone` and 2 more); `$FD9C`-`$FD9D` (`PlayerIndex`); `$FEC5` (`CaveGrid+285`) |
| Ports in | `$DFFE` |
| Ports out | `$DFFF` |

### `MoveLeft` (`$8428`)

**Move the player one cell left (the old cell 0)**

Witness: L1 4365 (c1, rzx x32).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3,981 calls (`stage1/rzx32` 486, `stage1/rzx26` 400, `stage1/rzx29` 206 and 30 more) |

### `TryRight` (`$8437`)

**The right key: move or act to the right**

As TryLeft `$83C3` with PlayerFacing = 3, column 29 the edge, RightSpecial `$9494` (continuation MoveRight), MoveRight `$849E`.

Witness: L1 36883 (c1, hiscore, lives, timer, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 257 calls, 33,893 t-states own (0.00 %) |
| Called from | `PlayerStep` |
| Calls | `MoveRight`, `RightSpecial` (tail), `BlockWall` |
| Reads | `$FD9C`-`$FD9D` (`PlayerIndex`); `$FEC6`-`$FECC` (`CaveGrid+286`); `$FF5B`-`$FF63` (`CaveGrid+435`); `$FF98`-`$FF9E` (`CaveGrid+496`) |
| Writes | `$FD80`-`$FD86` (`KeyMoved`, `VarsFD81`, `GemDigits`, `CaveDone` and 2 more) |
| Ports in | `$DFFE` |
| Ports out | `$DFFF` |

### `MoveRight` (`$849E`)

**Move the player one cell right**

Witness: L1 4761 (c1, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 23 calls, 2,045 t-states own (0.00 %) |
| Called from | `TryRight`, `RightSpecial` (tail) |
| Reads | `$FD9C`-`$FD9D` (`PlayerIndex`) |
| Writes | `$FD9C`-`$FD9D` (`PlayerIndex`); `$FEC5`-`$FECB` (`CaveGrid+285`); `$FF5A`-`$FF62` (`CaveGrid+434`); `$FF97`-`$FF9D` (`CaveGrid+495`) |

### `TryUp` (`$84AD`)

**The up key: move or act upward**

As TryLeft, row 0 the edge; boulders block; UpSpecial `$9414`, MoveUp `$84E6`.

Witness: L1 31376 (c1, hiscore, lives, timer, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 234 calls, 11,370 t-states own (0.00 %) |
| Called from | `PlayerStep` |
| Ports in | `$FBFE` |
| Ports out | `$FBFF` |

### `MoveUp` (`$84E6`)

**Move the player one row up**

Witness: L1 3803 (rzx x32).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 3,627 calls (`stage1/rzx32` 387, `stage1/rzx24` 208, `stage1/rzx26` 204 and 29 more) |

### `TryDown` (`$84F9`)

**The down key: move or act downward**

Row 19 the edge; DownSpecial `$93CE`, MoveDown `$8535`.

Witness: L1 26738 (c1, hiscore, lives, timer, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 234 calls, 15,445 t-states own (0.00 %) |
| Called from | `PlayerStep` |
| Calls | `MoveDown`, `DownSpecial` (tail), `BlockWall` |
| Reads | `$FD9C`-`$FD9D` (`PlayerIndex`); `$FEE2`-`$FEEA` (`CaveGrid+314`); `$FF00`-`$FF08` (`CaveGrid+344`); `$FF1E`-`$FF1F` (`CaveGrid+374`); `$FF3C`-`$FF3D` (`CaveGrid+404`); `$FF5A`-`$FF5B` (`CaveGrid+434`); 2 more ranges |
| Writes | `$FD80` (`KeyMoved`) |
| Ports in | `$FDFE` |
| Ports out | `$FDFF` |

### `MoveDown` (`$8535`)

**Move the player one row down**

Witness: L1 4052 (c1, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 12 calls, 1,468 t-states own (0.00 %) |
| Called from | `TryDown`, `DownSpecial` (tail), `Continue` |
| Reads | `$FD9C`-`$FD9D` (`PlayerIndex`) |
| Writes | `$FD9C`-`$FD9D` (`PlayerIndex`); `$FEC4`-`$FECC` (`CaveGrid+284`); `$FEE2`-`$FEE3` (`CaveGrid+314`); `$FF00`-`$FF01` (`CaveGrid+344`); `$FF1E`-`$FF1F` (`CaveGrid+374`); `$FF3C`-`$FF3D` (`CaveGrid+404`); 2 more ranges |

### `PlayerStep` (`$8556`)

**One player step: the four keys in turn until one moves the player**

ClearStepFlags `$E858` (DugEarth, KeyMoved, BoulderPushed 0). PlayerIndex 0 skips only TryLeft (JR Z,PlayerStepSkip lands on the TryRight call; no recording has it). TryLeft, TryRight, TryUp, TryDown, each only while KeyMoved is not `$FF`; DigNoiseIfDug `$E860`.

Witness: L1 42098 (c1, hiscore, lives, timer, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 265 calls, 72,211 t-states own (0.01 %) |
| Called from | `KeysStep` |
| Calls | `TryLeft`, `TryRight`, `TryUp`, `TryDown`, `ClearStepFlags`, `DigNoiseIfDug` |
| Reads | `$FD80` (`KeyMoved`); `$FD9C`-`$FD9D` (`PlayerIndex`) |
| Writes | `$E82E` (`BoulderPushed`) |

### `CollectGem` (`$8595`)

**Take a gem: the points, the count, the exit**

AddGemValue `$8376`, ShowScore `$8342`, CountGem `$8394`; when ExitOpen became `$FF`, ExitOpenSound `$9072`.

Witness: L1 1692 (c1, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 2 calls, 185 t-states own (0.00 %) |
| Called from | `DownSpecial`, `RightSpecial` |
| Calls | `ShowScore`, `AddGemValue`, `CountGem` |
| Reads | `$FD85` (`ExitOpen`) |

### `KeysStep` (`$8759`)

**The fire key chooses FireStep, else PlayerStep**

The fire key's site (LD A,`$7F` at `$8759`, AND `$04` at `$875F`: SPACE half row, bit 2 = M) is written by RedefineKeys `$8C30`.

Witness: L1 43776 (c1, hiscore, lives, timer, rzx x32).

[Animation: `KeysStep` at work](img/routines/KeysStep.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 265 calls, 19,792 t-states own (0.00 %) |
| Called from | `PlayCave` |
| Calls | `PlayerStep` |
| Ports in | `$7FFE` |
| Ports out | `$7FFF` |

### `FireLeft` (`$876B`)

**Fire left: act on the left cell without moving**

Earth: DigInPlace `$E7FE`. An object: CollectLeft `$9621`. A boulder: FireLeftBoulder `$879F`.

Witness: L1 1678 (rzx x23).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,678 calls (`stage1/rzx24` 323, `stage1/rzx21` 156, `stage1/rzx23` 122 and 20 more) |

### `FireLeftBoulder` (`$879F`)

**Fire left on a boulder: push it when the cell beyond is empty**

The boulder not in column 0 (the test is on PlayerIndex - 1) and the cell beyond it 0: the boulder moves there (`$87BA`), its old cell gets `$20` (`$87BD`), ThudSound `$8228`. BoulderPushed is not written.

Witness: L1 304 (rzx x15); the push `$87BA` ran 30 times (rzx x6: rzx09, 16, 24, 26, 27, 28; work/stage2/execs.json).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `FireRight` (`$87C3`)

**Fire right: act on the right cell without moving**

Witness: L1 1678 (rzx x23).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,678 calls (`stage1/rzx24` 323, `stage1/rzx21` 156, `stage1/rzx23` 122 and 20 more) |

### `FireUp` (`$881D`)

**Fire up: act on the cell above without moving**

Witness: L1 1678 (rzx x23).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,678 calls (`stage1/rzx24` 323, `stage1/rzx21` 156, `stage1/rzx23` 122 and 20 more) |

### `FireDown` (`$8849`)

**Fire down: act on the cell below without moving**

Witness: L1 1678 (rzx x23).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,678 calls (`stage1/rzx24` 323, `stage1/rzx21` 156, `stage1/rzx23` 122 and 20 more) |

### `FireStep` (`$8878`)

**The fire key held: each direction key acts on the next cell**

Witness: L1 1678 (rzx x23).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1,678 calls (`stage1/rzx24` 323, `stage1/rzx21` 156, `stage1/rzx23` 122 and 20 more) |

### `ForceField` (`$914C`)

**Walked into a force field (9): blocked, 12 TimerSteps at once (3 bar pixels)**

Witness: L1 11 (rzx x5).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 11 calls (`stage1/rzx26` 5, `stage1/rzx24` 2, `stage1/rzx22` 2 and 2 more) |

### `UpSpecialCell` (`$915F`)

**The special cell above the player: its handler**

HL = the cell above (code `$07-$0F`, UpSpecialCheck `$93C7`). Gem: CollectGem `$8595`, MoveUp `$84E6`; jelly bean JellyBean `$91F7`; force field ForceField `$914C`; anti-gravity arrow AntiGravTake `$A7C7`; switch box: RET (blocks); potion: TakePotion `$91C9`, then the tests go on; teleporter TeleportUp `$926E`; bubble BubbleUp `$934F`; fire WalkIntoFire `$91AE` (PlayerKilled `$7FFD` = `$FF`, Continue `$9410`).

Known only from the code: the fire test `$9194` and the tail `$919A` never ran: no build walked up into fire or a potion. The tail is reached after a potion taken from above: CALL Z,TakePotion returns with HL at the `$FF` that ends LifeTune, every later test fails, CP `$0F` leaves carry, and SBC gives PlayerIndex - 30: the player moves up into the potion's cell, by luck of the carry. WalkIntoFire itself ran in the stage 2 recording death-fire (frame 279, from LeftSpecial `$94D6`, TryLeft's dispatcher: cave 4, one step left into fire).

Witness: L1 517 (rzx x32).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 517 calls (`stage1/rzx16` 60, `stage1/rzx31` 40, `stage1/rzx29` 35 and 29 more) |

### `PotionTune` (`$91C1`)

**The extra-life tune: PlayTune LifeTune `$AC5F`**

Witness: L1 6 (rzx x6).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 6 calls (`stage1/rzx27` 1, `stage1/rzx19` 1, `stage1/rzx22` 1 and 3 more) |

### `TakePotion` (`$91C9`)

**The potion (`$0C`): a life (up to 9), its tune, 20 points**

Witness: L1 6 (rzx x6).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 6 calls (`stage1/rzx28` 1, `stage1/rzx19` 1, `stage1/rzx27` 1 and 3 more) |

### `TimeBarRefillStep` (`$91DB`)

**Shift a set pixel into the time bar from the left**

Witness: L1 4224 (rzx x23).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 4,224 calls (`stage1/rzx32` 640, `stage1/rzx26` 544, `stage1/rzx29` 352 and 20 more) |

### `TeleportUp` (`$926E`)

**A teleporter above: erase it, go to the next teleporter**

Witness: L1 16 (rzx x11).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 16 calls (`stage1/rzx26` 4, `stage1/rzx16` 2, `stage1/rzx32` 2 and 8 more) |

### `BubbleUp` (`$934F`)

**Push a bubble up: into earth or empty it moves, into fire it bursts**

Witness: L1 206 (rzx x16).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 206 calls (`stage1/rzx16` 52, `stage1/rzx31` 36, `stage1/rzx29` 28 and 13 more) |

### `BubbleBurst` (`$9378`)

**A bubble pushed into fire: the cell becomes `$10` (the burst), BubbleScore**

Witness: L1 136 (rzx x21).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 136 calls (`stage1/rzx24` 23, `stage1/rzx32` 21, `stage1/rzx31` 16 and 18 more) |

### `BubbleScore` (`$93B6`)

**The burst bubble: RaspSound, 100 points**

Witness: L1 136 (rzx x21).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 136 calls (`stage1/rzx24` 23, `stage1/rzx32` 21, `stage1/rzx31` 16 and 18 more) |

### `UpSpecialCheck` (`$93C7`)

**A cell code above `$0F` above the player blocks; else UpSpecialCell**

Witness: L1 523 (rzx x32).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 523 calls (`stage1/rzx16` 60, `stage1/rzx31` 40, `stage1/rzx29` 35 and 29 more) |

### `DownSpecial` (`$93CE`)

**The cell below is a special: its handler**

Witness: L1 1120 (c1, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 6 calls, 1,305 t-states own (0.00 %) |
| Called from | `TryDown` (tail) |
| Calls | `MoveDown` (tail), `CollectGem`, `BubbleDown` (tail) |
| Reads | `$FF1E` (`CaveGrid+374`); `$FF5A` (`CaveGrid+434`); `$FF78` (`CaveGrid+464`) |
| Writes | `$FD87`-`$FD88` (`Continuation`) |

### `Continue` (`$9410`)

**JP (HL): the stored continuation Continuation `$FD87`**

Witness: L1 1608 (c1, rzx x28).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 1 call, 20 t-states own (0.00 %) |
| Called from | `BubbleDown` (tail) |
| Calls | `MoveDown` |
| Reads | `$FD87`-`$FD88` (`Continuation`) |

### `UpSpecial` (`$9414`)

**The cell above is a special: its handler**

Witness: L1 523 (rzx x32).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 523 calls (`stage1/rzx16` 60, `stage1/rzx31` 40, `stage1/rzx29` 35 and 29 more) |

### `TeleportDown` (`$941F`)

**A teleporter below: MoveUp, erase it, go to the next teleporter**

It calls MoveUp `$84E6` (`$942B`), not MoveDown, then writes `$20` into the cell below. With no teleporter found (or only one in cell 599: the test is on BC after CPIR, `$9440`) it returns with the player one row above where he stood.

Witness: L1 11 (rzx x8).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 11 calls (`stage1/rzx24` 3, `stage1/rzx26` 2, `stage1/rzx05` 1 and 5 more) |

### `PotionDown` (`$9465`)

**The potion below: TakePotion, then continue**

Witness: L1 6 (rzx x6).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 4 calls (`stage1/rzx28` 1, `stage1/rzx09` 1, `stage1/rzx22` 1 and 1 more) |

### `BubbleDown` (`$946B`)

**Push a bubble down**

Witness: L1 592 (c1, rzx x21).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 5 calls, 807 t-states own (0.00 %) |
| Called from | `DownSpecial` (tail) |
| Calls | `Continue` (tail) |
| Reads | `$FF78` (`CaveGrid+464`); `$FF96` (`CaveGrid+494`) |
| Writes | `$FF78` (`CaveGrid+464`) |

### `RightSpecial` (`$9494`)

**The cell to the right is a special (TryRight `$8437`): its handler, continuation MoveRight**

Witness: L1 959 (c1, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 1 call, 95 t-states own (0.00 %) |
| Called from | `TryRight` (tail) |
| Calls | `MoveRight` (tail), `CollectGem` |
| Reads | `$FF5F` (`CaveGrid+439`) |
| Writes | `$FD87`-`$FD88` (`Continuation`) |

### `LeftSpecial` (`$94D6`)

**The cell to the left is a special (TryLeft `$83C3`): its handler, continuation MoveLeft**

Witness: L1 847 (rzx x32).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 848 calls (`stage1/rzx12` 90, `stage1/rzx29` 72, `stage1/rzx31` 58 and 30 more) |

### `TeleportRight` (`$9518`)

**A teleporter to the right**

Witness: L1 18 (rzx x10).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 18 calls (`stage1/rzx26` 4, `stage2/rzx04/cap` 3, `stage1/rzx24` 2 and 7 more) |

### `TeleportLeft` (`$955E`)

**A teleporter to the left**

Witness: L1 13 (rzx x9).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 13 calls (`stage1/rzx26` 4, `stage1/rzx28` 2, `stage1/rzx32` 1 and 6 more) |

### `BubbleRight` (`$95A4`)

**Push a bubble right**

Witness: L1 499 (rzx x19).

[Animation: `BubbleRight` at work](img/routines/BubbleRight.gif)

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 499 calls (`stage1/rzx32` 260, `stage1/rzx25` 45, `stage1/rzx26` 39 and 16 more) |

### `BubbleLeft` (`$95D5`)

**Push a bubble left**

Witness: L1 380 (rzx x20).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 380 calls (`stage1/rzx12` 61, `stage1/rzx31` 51, `stage1/rzx29` 46 and 17 more) |

### `CollectObject` (`$9606`)

**Take the object at the saved cell (the fire key): gem, jelly bean, potion, arrow**

Witness: L1 302 (rzx x23).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 302 calls (`stage1/rzx24` 42, `stage1/rzx21` 31, `stage1/rzx23` 28 and 20 more) |

### `CollectNone` (`$9620`)

**RET**

Witness: L1 24 (rzx x11).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rzx18`, `stage1/rzx25`, `stage1/rzx23` and 6 more) |

### `CollectLeft` (`$9621`)

**Fire left on an object: take it**

Witness: L1 126 (rzx x18).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 126 calls (`stage1/rzx24` 43, `stage1/rzx21` 13, `stage1/rzx23` 13 and 15 more) |

### `CollectLeftClear` (`$9648`)

**The saved cell becomes `$20`**

Witness: L1 1 (rzx x1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rzx24`) |

### `CollectRight` (`$964E`)

**Fire right on an object: take it**

Witness: L1 94 (rzx x16).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 94 calls (`stage1/rzx21` 13, `stage1/rzx22` 13, `stage1/rzx23` 12 and 13 more) |

### `CollectRightClear` (`$9675`)

**The saved cell becomes `$20`**

Witness: L1 2 (rzx x1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rzx24`) |

### `CollectUp` (`$967B`)

**Fire up on an object: take it**

Witness: L1 37 (rzx x18).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 37 calls (`stage1/rzx29` 4, `stage1/rzx19` 4, `stage1/rzx26` 4 and 15 more) |

### `CollectUpClear` (`$96A2`)

**The saved cell becomes `$20`**

Witness: L1 1 (rzx x1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rzx24`) |

### `CollectDown` (`$96A8`)

**Fire down on an object: take it**

Witness: L1 55 (rzx x18).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 55 calls (`stage1/rzx16` 10, `stage1/rzx28` 6, `stage1/rzx22` 5 and 15 more) |

### `CollectDownClear` (`$96CF`)

**The saved cell becomes `$20`**

Witness: L1 2 (rzx x2).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/rzx22`, `stage1/rzx24`) |

### `BubbleRightMove` (`$9980`)

**Mark the cell beyond a bubble pushed right**

The bubble is already written (`$95CF`). The cell beyond its new place gets `$20` when it is 0; when the new place is in column 29 the loop ends with HL = 0 and the `$20` goes to `$0000` (the ROM, no effect). Then Continue `$9410`.

Witness: L1 400 (rzx x19).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 400 calls (`stage1/rzx32` 213, `stage1/rzx26` 37, `stage1/rzx25` 31 and 16 more) |

### `BubbleLeftMove` (`$99A0`)

**Mark the cell beyond a bubble pushed left**

The bubble is already written (`$9600`). The cell beyond its new place gets `$20` when it is 0; when the new place is in column 0 the loop ends with HL = 0 and the `$20` goes to `$0000` (the ROM, no effect). Then Continue `$9410`.

Witness: L1 306 (rzx x18).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 306 calls (`stage1/rzx12` 47, `stage1/rzx29` 38, `stage1/rzx18` 37 and 15 more) |

### `CollectAntiGrav` (`$A63E`)

**Take the anti-gravity arrow with the fire key**

Witness: L1 302 (rzx x23).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 302 calls (`stage1/rzx24` 42, `stage1/rzx21` 31, `stage1/rzx23` 28 and 20 more) |

### `DigInPlace` (`$E7FE`)

**The fire key on earth: dig it without moving, with a noise**

Witness: L1 167 (rzx x16).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 167 calls (`stage1/rzx24` 84, `stage1/rzx26` 15, `stage1/rzx29` 13 and 13 more) |

### `PushBoulder` (`$E81F`)

**Push a boulder left or right when the cell beyond is empty**

Witness: L1 434 (c1, rzx x29).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 7 calls, 266 t-states own (0.00 %) |
| Called from | `TryLeft` |
| Reads | `$FEC2` (`CaveGrid+282`) |

### `ClearMoveFlags` (`$E82F`)

**KeyMoved and BoulderPushed 0**

Witness: L1 42098 (c1, hiscore, lives, timer, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 265 calls, 14,206 t-states own (0.00 %) |
| Called from | `ClearStepFlags` (tail) |
| Writes | `$E82E` (`BoulderPushed`); `$FD80` (`KeyMoved`) |

### `ClearStepFlags` (`$E858`)

**DugEarth 0, then ClearMoveFlags**

Witness: L1 42098 (c1, hiscore, lives, timer, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 265 calls, 7,950 t-states own (0.00 %) |
| Called from | `PlayerStep` |
| Calls | `ClearMoveFlags` (tail) |
| Writes | `$E857` (`DugEarth`) |

### `BlockWall` (`$E869`)

**A wall stops the move (the return address dropped); earth sets DugEarth**

Witness: L1 19281 (c1, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 41 calls, 3,195 t-states own (0.00 %) |
| Called from | `TryLeft`, `TryRight`, `TryDown` |
| Reads | `$FEC4`-`$FECC` (`CaveGrid+284`); `$FEE2`-`$FEEA` (`CaveGrid+314`); `$FF00`-`$FF01` (`CaveGrid+344`); `$FF1E`-`$FF1F` (`CaveGrid+374`); `$FF3C`-`$FF3D` (`CaveGrid+404`); `$FF5A`-`$FF63` (`CaveGrid+434`); 2 more ranges |
| Writes | `$E857` (`DugEarth`) |

## menu

`src/game/menu.asm`

### `ResetAll` (`$85CF`)

**Clear the variables and set the start values**

ClearVars `$821A`, ResetGame `$82E6`.

Witness: L1 9 (c1, lives, menu).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 5 calls, 255 t-states own (0.00 %) |
| Called from | `GameEntry` |
| Calls | `ClearVars`, `ResetGame` |

### `ClearScreen` (`$860E`)

**Clear the screen: attributes `$47`, then the pixel wipe**

Attributes `$47` (bright white on black), WipeScreen `$8DE3`.

Witness: L1 104 (c1, hiscore, lives, menu, timer, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 9 calls, 187,239 t-states own (0.02 %) |
| Called from | `StartGameEntry`, `RedefineKeys`, `ShowPasswordPrompt`, `ClearScreenCave`, `ClearAndKeyboard` |
| Calls | `WipeScreen` |
| Reads | `$5800`-`$5AFE` (screen) |
| Writes | `$5800`-`$5AFF` (screen) |

### `WipeInLogo` (`$8979`)

**Wipe the title logo in, pixel line by line, from LogoPixels `$B300`**

64 lines: each a Pause `$8C0E`, then the 32 bytes of the line and every 8th line below it from `$B300` (the screen address + `$7300`).

Witness: L1 9 (c1, lives, menu).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 5 calls, 10,968,479 t-states own (1.00 %) |
| Called from | `ShowLogo` |
| Calls | `LineAddr`, `Pause` |
| Reads | `$B300`-`$BAFF` (`LogoPixels`) |
| Writes | `$4000`-`$47FF` (screen) |

### `ShowMenuTexts` (`$8A3C`)

**Print the menu's lines: MenuTexts `$AB00` and ShowControlTexts `$ECC5`**

Witness: L1 10 (c1, lives, menu).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 5 calls, 1,204 t-states own (0.00 %) |
| Called from | `DrawTitle` |
| Calls | `PrintText`, `ShowControlTexts` |

### `FillAttrs` (`$8A74`)

**Fill D attributes with A from row B, column C**

Witness: L1 3260 (c1, hiscore, lives, menu, timer, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 40 calls, 80,451 t-states own (0.01 %) |
| Called from | `ColourMenuTexts`, `ColourLevelLivesScore`, `RedefineKeys`, `ShowPasswordPrompt` |
| Calls | `AttrAddr` |
| Writes | `$5800`-`$581F` (screen); `$58C5`-`$58D9` (screen); `$5905`-`$5919` (screen); `$5945`-`$59D9` (screen); `$5A24`-`$5A3B` (screen); `$5A64`-`$5A79` (screen) |

### `ColourMenuTexts` (`$8A83`)

**Colour the menu's lines**

Witness: L1 10 (c1, lives, menu).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 5 calls, 893 t-states own (0.00 %) |
| Called from | `DrawTitle` |
| Calls | `FillAttrs` |

### `GameEntry` (`$8B20`)

**The game's entry (RANDOMIZE USR 35616): reset, the title, the title tune, the menu**

ResetAll `$85CF`, DrawTitle `$8AC8`, PlayTitleTune `$8A35`, then MenuKeys.

Witness: L1 9 (c1, lives, menu).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 3 calls, 822 t-states own (0.00 %) |
| Called from | `ChooseControl` (tail) |
| Calls | `ResetAll`, `PlayTitleTune`, `DrawTitle`, `NewGame`, `RedefineKeys`, `ChooseControl` (tail) |
| Ports in | `$F7FE` |
| Ports out | `$F7FF` |

### `MenuKeys` (`$8B29`)

**Keys 1-5 of the menu; the high scores when the title tune ran out**

HL = PlayTune's end; HL = `$B269` (TitleTune's end) runs ShowHiScores `$B2E4`. Key 1 NewGame `$8BE5`, 2 RedefineKeys `$8C30`, 3 and 4 ChooseControl `$ECE3`, 5 ResetMachine `$8B65`.

Witness: L1 11 (c1, lives, menu, rzx x1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings run into, not called (`stage1/lives`, `stage1/rzx01`) |

### `ResetMachine` (`$8B65`)

**Key 5: interrupts off, then JP 0 (the machine resets)**

Witness: L1 1 (menu).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 1 call (`stage1/menu` 1) |

### `WipeScreen` (`$8DE3`)

**Wipe the pixels away: 8 passes shifting each byte pair apart**

Witness: L1 104 (c1, hiscore, lives, menu, timer, rzx x32).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 9 calls, 13,851,327 t-states own (1.27 %) |
| Called from | `ClearScreen` |
| Reads | `$4000`-`$57FF` (screen) |
| Writes | `$4000`-`$57FF` (screen) |

### `ShowLogo` (`$9091`)

**Wipe in the logo, copy LogoAttrs `$FC00` to the top third's attributes**

Witness: L1 9 (c1, lives, menu).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 5 calls, 28,373 t-states own (0.00 %) |
| Called from | `DrawTitle` |
| Calls | `WipeInLogo` |
| Reads | `$FC00`-`$FCFF` (`LogoAttrs`) |
| Writes | `$5800`-`$58FF` (screen) |

## password

`src/game/password.asm`

### `StartGame` (`$85D6`)

**Start a game: the password, 5 lives, the score 0**

CaveDigits `$FD7E` = 0, 1; Password `$8F29` (sets the cave); Lives `$FD93` = 5, ScoreDigits 0.

Witness: L1 3 (c1, lives, rzx x1).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 1 call, 213 t-states own (0.00 %) |
| Called from | `StartGameEntry` |
| Calls | `Password` |
| Reads | `$FD94`-`$FD98` (`ScoreDigits`) |
| Writes | `$FD7E`-`$FD7F` (`CaveDigits`); `$FD93`-`$FD99` (`Lives`, `ScoreDigits`) |

### `ShowPasswordPrompt` (`$8DFF`)

**Clear the screen, print EnterPasswordText on row 0**

Witness: L1 3 (c1, lives, rzx x1).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 1 call, 117 t-states own (0.00 %) |
| Called from | `EnterPassword` |
| Calls | `PrintText`, `ClearScreen`, `FillAttrs` |

### `KeyClick` (`$8E18`)

**A short click for a typed or deleted character**

Witness: L1 7 (hiscore).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1`; in the other recordings 7 calls (`stage1/hiscore` 7) |

### `EnterPassword` (`$8E2D`)

**Read the password into PasswordBuffer `$FD00`**

The buffer to spaces, the prompt; WaitKey: '0' deletes, 'e' (ENTER) ends, space and A-Z are stored, at most 20.

Witness: L1 3 (c1, lives, rzx x1).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 1 call, 23,476 t-states own (0.00 %) |
| Called from | `Password` |
| Calls | `WaitKey`, `ShowPasswordPrompt` |
| Reads | `$A93B` (`KeyTable+59`); `$A968` (`KeyTable+104`); `$FD00`-`$FD12` (`PasswordBuffer`) |
| Writes | `$FD00`-`$FD13` (`PasswordBuffer`) |

### `FindPassword` (`$8E91`)

**Compare PasswordBuffer with 50 records of 20 bytes from CaveNames**

Out: B = the record that matched (0-49), or 50 when none did.

Witness: L1 3 (c1, lives, rzx x1).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 1 call, 6,872 t-states own (0.00 %) |
| Called from | `Password` |
| Reads | `$9700`-`$9A48` (`CaveNames`, `BubbleRightMove`, `BubbleLeftMove`, `CaveNamesPad` and 1 more); `$9A5C` (`MapGlyphs+92`); `$9A70` (`MapGlyphs+112`); `$9A84` (`MapAttrs+4`); `$9A98` (`MapPatchLeftover+8`); `$9AAC` (`EarthFallGuard+6`); 3 more ranges |

### `PasswordFlashText` (`$8EB6`)

**A match: colour the prompt line in cycling colours**

Known only from the code: no recording types a valid password.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PasswordFlashStep` (`$8ED2`)

**Rotate the prompt line's attributes one cell left**

Known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PasswordAccepted` (`$8EE4`)

**A match: the coloured line and a rising buzz**

Known only from the code.

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `PasswordRejected` (`$8F08`)

**No match: RET (the 1990 version dropped the failure flash PasswordRejectedOld `$8F09`)**

Witness: L1 3 (c1, lives, rzx x1).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 1 call, 10 t-states own (0.00 %) |
| Called from | `Password` |

### `Password` (`$8F29`)

**Enter and check the password; set the first cave**

EnterPassword `$8E2D`, FindPassword `$8E91`. No match: cave 1. Record B: CaveNumber = B + 1, CaveDigits counted up to it, PasswordAccepted `$8EE4`.

Witness: L1 3 (c1, lives, rzx x1).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 1 call, 125 t-states own (0.00 %) |
| Called from | `StartGame` |
| Calls | `EnterPassword`, `FindPassword`, `PasswordRejected` |
| Writes | `$FD7E`-`$FD7F` (`CaveDigits`); `$FD91` (`CaveNumber`) |

## keys

`src/game/keys.asm`

### `Pause` (`$8C0E`)

**Wait 30 x 256 loop turns, then LineAddr**

Witness: L1 576 (c1, lives, menu).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 320 calls, 32,146,563 t-states own (2.94 %) |
| Called from | `WipeInLogo` |
| Calls | `LineAddr` |

### `WaitKey` (`$8C1D`)

**Wait until a key of KeyTable is down**

Scans the 40 records over and over. Out: HL = the record's mask byte, the character at HL + 1.

No release wait: a key still down when WaitKey is called again is taken again (the menu recording's redefinition took 2 for left, right and up).

Witness: L1 69199 (c1, hiscore, lives, menu, rzx x1).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 162 calls, 17,164,713 t-states own (1.57 %) |
| Called from | `RedefineKeys`, `EnterPassword` |
| Reads | `$A900`-`$A976` (`KeyTable`) |
| Ports in | `$7FFE`, `$BFFE`, `$DFFE`, `$EFFE`, `$F7FE`, `$FBFE`, `$FDFE`, `$FEFE` |
| Ports out | `$7FFF`, `$BFFF`, `$DFFF`, `$EFFF`, `$F7FF`, `$FBFF`, `$FDFF`, `$FEFF` |

### `RedefineKeys` (`$8C30`)

**Key 2: define the left, right, up, down and fire keys**

ClearAndKeyboard `$ECDC`; for each prompt of KeyPrompts `$A978`: WaitKey, the key's character printed, its row and mask written into the key sites (`$83C4` / `$83CA`, `$876C` / `$8772` ...), RaspSound `$90A0`.

Starts with ClearAndKeyboard: the keyboard code is back in the sites before the keys are written, so a redefinition always selects the keyboard. The fire prompt writes KeysStep only.

Witness: L1 2 (c1, menu).

[Animation: `RedefineKeys` at work](img/routines/RedefineKeys.gif)

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 1 call, 1,773 t-states own (0.00 %) |
| Called from | `GameEntry` |
| Calls | `PrintText`, `ClearScreen`, `FillAttrs`, `WaitKey`, `RaspSound`, `ClearAndKeyboard` |
| Reads | `$A91B`-`$A92B` (`KeyTable+27`); `$A954`-`$A958` (`KeyTable+84`); `$A96F`-`$A970` (`KeyTable+111`) |
| Writes | `$83C4`-`$83CA` (`TryLeft+1`); `$8438`-`$843E` (`TryRight+1`); `$84AE`-`$84B4` (`TryUp+1`); `$84FA`-`$8500` (`TryDown+1`); `$875A`-`$8772` (`KeysStep+1`, `FireLeft`); `$87C4`-`$87CA` (`FireRight+1`); 2 more ranges |

### `SaveKeyboardCode` (`$EB66`)

**Copy the key sites into KeyboardCode**

Witness: L1 2 (c1, menu).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 1 call, 1,936 t-states own (0.00 %) |
| Called from | `JoystickControl` |
| Reads | `$83C3`-`$83CB` (`TryLeft`); `$8437`-`$843F` (`TryRight`); `$84AD`-`$84B5` (`TryUp`); `$84F9`-`$8501` (`TryDown`); `$8759`-`$8773` (`KeysStep`, `FireLeft`); `$87C3`-`$87CB` (`FireRight`); 2 more ranges |
| Writes | `$EB15`-`$EB65` (`KeyboardCode`) |

### `KeyboardControl` (`$EBCA`)

**Key 3: the keyboard code back into the key sites**

Witness: L1 4 (c1, menu).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 2 calls, 3,883 t-states own (0.00 %) |
| Called from | `ClearAndKeyboard`, `ChooseControl` |
| Reads | `$EB15`-`$EB65` (`KeyboardCode`) |
| Writes | `$83C3`-`$83CB` (`TryLeft`); `$8437`-`$843F` (`TryRight`); `$84AD`-`$84B5` (`TryUp`); `$84F9`-`$8501` (`TryDown`); `$8759`-`$8773` (`KeysStep`, `FireLeft`); `$87C3`-`$87CB` (`FireRight`); 2 more ranges |

### `JoystickControl` (`$EC2E`)

**Key 4: the joystick code into the key sites**

SaveKeyboardCode first: key 4 pressed twice saves the Kempston code over KeyboardCode, and key 3 then restores the Kempston code; a redefinition made after the last key 4 is lost on key 3 (KeyboardCode changes only here).

Witness: L1 2 (c1, menu).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 1 call, 1,953 t-states own (0.00 %) |
| Called from | `ChooseControl` |
| Calls | `SaveKeyboardCode` |
| Reads | `$EAC4`-`$EB14` (`KempstonCode`) |
| Writes | `$83C3`-`$83CB` (`TryLeft`); `$8437`-`$843F` (`TryRight`); `$84AD`-`$84B5` (`TryUp`); `$84F9`-`$8501` (`TryDown`); `$8759`-`$8773` (`KeysStep`, `FireLeft`); `$87C3`-`$87CB` (`FireRight`); 2 more ranges |

### `ShowControlTexts` (`$ECC5`)

**Print ControlTexts**

Witness: L1 10 (c1, lives, menu).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 5 calls, 522 t-states own (0.00 %) |
| Called from | `ShowMenuTexts` |
| Calls | `PrintText` |

### `ClearAndKeyboard` (`$ECDC`)

**ClearScreen, KeyboardControl**

Witness: L1 2 (c1, menu).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 1 call, 45 t-states own (0.00 %) |
| Called from | `RedefineKeys` |
| Calls | `ClearScreen`, `KeyboardControl` |

### `ChooseControl` (`$ECE3`)

**Keys 3 and 4 of the menu**

Witness: L1 5 (c1, menu).

| | |
| --- | --- |
| Runs (c1: power-on, the covertape side at ROM speed, the menu and play) | 2 calls, 222 t-states own (0.00 %) |
| Called from | `GameEntry` (tail) |
| Calls | `GameEntry` (tail), `SwitchSound`, `KeyboardControl`, `JoystickControl` |
| Ports in | `$F7FE` |
| Ports out | `$F7FF` |
