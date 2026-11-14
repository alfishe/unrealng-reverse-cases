# 12. Routine reference

Every code entry of the game, in address order by module (`src/game/<module>.asm`). The name, the title and
the description are the source's (`src/game/game.ann`); the rest is what the recordings saw: `work/stage1/c1g` (c1g: the c1 recording's game window, from the jump to `$8382` (frame 15752 T 33930): the menu and play), and the case's other recordings (`case.json` `read_builds`, `code_builds`): their calls in a Runs row of their own, their callers, callees, reads and writes (`read_builds` only) with the others'. They are local, not in the repository; the WALKTHROUGH's commands rebuild them.
Runs count the calls of the entry itself; the time is its own t-states (callees excluded) and their share
of the recording. Memory ranges name the label at or below their first byte (inner labels too, `Label+offset`)
and the entries they cover. The interrupt's acceptance (the vector read, the return address pushed) is
the handler's, not the interrupted routine's. An entry no recording reached says so; one the case's other
recordings ran gives their calls.
Written by `kit/refdocs.py`; edit `src/game/game.ann`, then run `kit/mkgame.py --case . --install`
(see [3. Build and load](03-build-and-load.md)) and `kit/refdocs.py --case .`.
The parts of the medium (`case.json` `ref_parts`: The tape, The loader's second stage, The main block) follow the
game, each under its own heading (a part of segments one a segment) with its modules, its source, its annotations
and its recordings.

| Module | Entries | Code entries |
| --- | --- | --- |
| [`menu`](#menu) | `$6000`-`$7B7F`, `$9ED8`-`$A021`, `$A053`-`$A102`, `$A729`-`$A83E` | 3 of 12 |
| [`panel`](#panel) | `$7B80`-`$7FFF`, `$866A`-`$87D3`, `$88B0`-`$8907`, `$9AF1`-`$9B75`, `$A103`-`$A2F9`, `$A50C`-`$A52E` | 8 of 43 |
| [`beam`](#beam) | `$8000`-`$81B7`, `$8AC1`-`$8B9A`, `$8EBF`-`$9013`, `$9014`-`$9739`, `$9910`-`$9A56`, `$D500`-`$D6FF` | 30 of 44 |
| [`mainloop`](#mainloop) | `$81B8`-`$81D3`, `$81FF`-`$81FF`, `$8374`-`$8381`, `$843C`-`$8669`, `$87D4`-`$88AF`, `$8908`-`$8911` | 8 of 25 |
| [`sound`](#sound) | `$81D4`-`$81FC`, `$A83F`-`$A8CD`, `$AD79`-`$AFFF` | 10 of 21 |
| [`controls`](#controls) | `$81FD`-`$81FE`, `$973A`-`$990F` | 5 of 7 |
| [`render`](#render) | `$8200`-`$8373`, `$8960`-`$8AC0`, `$8B9B`-`$8EBE`, `$D200`-`$D4FF`, `$D700`-`$DFFF` | 13 of 30 |
| [`entry`](#entry) | `$8382`-`$843B` | 6 of 8 |
| [`levels`](#levels) | `$8912`-`$895F`, `$B000`-`$D1FF` | 1 of 4 |
| [`elements`](#elements) | `$9A57`-`$9AF0`, `$A506`-`$A50B`, `$A52F`-`$A728`, `$AAE3`-`$AD78` | 13 of 25 |
| [`hiscore`](#hiscore) | `$9B76`-`$9ED7`, `$A022`-`$A052` | 7 of 10 |
| [`interrupt`](#interrupt) | `$A2FA`-`$A505` | 5 of 5 |
| [`ending`](#ending) | `$A8CE`-`$AAE2` | 1 of 4 |

## menu

`src/game/menu.asm`

### `DrawMenuScreen` (`$9ED8`)

**Draw the options screen into the buffer `$E200` / `$E500`: panels, logo, options, hall of fame**

Unpacks the screen's attributes from the run-length list `$A053` (count, value; `$FF` ends) into 768 bytes at `$E200`, clears the pixel buffer `$E500`-`$FCFF` (a linear screen, 32 bytes a row), fills every character whose attribute is 2 with the dither `MenuDither` `$9F41`, then prints with `$8E3A` (records: attribute + `$80`, column, row, text; a byte with bit 7 starts the next record, `$FF` ends): "HALL OF FAME" (`$9F49`), the hall of fame's names (`$A022`) and scores (`$9FEB`), the logo and the options (`$9F59`). `$8B9B` or `$8C95` then copy the buffer to the screen.

Called by `HallOfFame` `$9BC0` (12 runs over all recordings).

Witness: L1 18 (c1, c1g, controls, energy-out, gameover, hof, kempston, menu, mine, nameedit, overload, rzx344752).

| | |
| --- | --- |
| Runs (c1g: the c1 recording's game window, from the jump to `$8382` (frame 15752 T 33930): the menu and play) | 1 call, 237,054 t-states own (0.07 %) |
| Runs (the other recordings) | 17 calls (`stage1/controls` 3, `docs/integrate/rec/nameedit` 2, `stage1/menu` 2 and 8 more) |
| Called from | `HallOfFame` |
| Calls | `PrintFull` |
| Reads | `$9F41` (`MenuDither`); `$A053`-`$A101` (`OptionsLayout`); `$E200`-`$FCFE` (`work space $E200+`) |
| Writes | `$E200`-`$FCFF` (`work space $E200+`) |

### `TitleScreen` (`$A729`)

**The title picture and its tune, then the options panel**

Called by `$840C` / `$8408` at `$8416` after the menu set-up `$9BC0`. Four waits `$8908`, `DI`, waits until no key is held (half rows read with A = 0), fills the attributes with the first one's value (`$5800` copied on), copies TitlePicture `$6000` (6912 bytes) to the screen, and plays the title tune (TitleTune `$AD79`) until a key; then falls into OptionsMenu.

Evidence: 10 runs (`c1g`, `controls`, `gameover`, `kempston`, `menu`, `mine`, `overload`).

Witness: L1 14 (c1, c1g, controls, energy-out, gameover, hof, kempston, menu, mine, nameedit, overload).

| | |
| --- | --- |
| Runs (c1g: the c1 recording's game window, from the jump to `$8382` (frame 15752 T 33930): the menu and play) | 1 call, 20,317,142 t-states own (6.05 %) |
| Runs (the other recordings) | 13 calls (`stage1/controls` 3, `stage1/menu` 2, `stage1/c1` 1 and 7 more) |
| Called from | `TitleLoop` |
| Calls | `Delay`, `TitleTune` |
| Reads | `$5800`-`$5AFE` (screen); `$6000`-`$7AFF` (`TitlePicture`); `$81FD` (`ControlMethod`); `$8E32`-`$8E33` (`RandomSeed`); `$9B7A`-`$9B7B` (`NamePointer`) |
| Writes | `$4000`-`$5AFF` (screen); `$81FD` (`ControlMethod`); `$8379` (`DemoFlag`); `$8E32`-`$8E33` (`RandomSeed`); `$9B7A`-`$9B7D` (`NamePointer`, `NameScreen`); `$A103`-`$A10F` (`MenuScroller`, `MessageNumber`, `MessageGlyph`, `MessageState` and 1 more); 1 more ranges |
| Ports in | `$00FE`, `$EFFE`, `$F7FE` |

### `OptionsMenu` (`$A757`)

**The options panel: credits on the menu line, keys 1-4 the control, 5 demo, 6 practice, 7 start**

`DI`; `$8C95` (the panel's buffers to the screen); a tone (TwoTone `$465A`, 14 frames); waits until no key; CreditsPause = `$FE`; MessageText = CreditsMessage; `EI` (the menu scroller runs).

OptionsHighlight: the line of the current ControlMethod `$81FD` (rows 8-11: `$4802` + 32 x method, attributes `$5901`): 12 attributes `$3A` (red on white), the marker `$9FE3` (an 8 x 8 diamond, drawn by `$9DE8` at the place kept in `$9B7C`).

OptionsKeyLoop, until a key: the random seed `$8E32` + 1 (so the game's randomness depends on how long the panel stays up); 7 START GAME (`$EFFE` bit 3), 5 DEMO (`$F7FE` bit 4: `$8379` = `$FF`), 6 PRACTICE (`$EFFE` bit 4: PracticeFlag `$8407` = `$FF`): the chosen line is highlighted (row 16, 13 or 14), the marker drawn there, a tone (`$28A0`, 8 frames), `DI`, MenuScroller = 0 and return to the new game. Keys 1-4 (`$F7FE` bits 0-3): ControlMethod = 0-3, a tone (`$1478`, 4 frames), the old marker wiped (the space glyph `$D200`), the old line back to `$38`, and OptionsHighlight again.

Evidence: entered 8 times (`c1g`, `controls`, `energy`, `kempston`, `menu`; `energy` and `kempston` start inside it). DEMO once (`menu`); the PRACTICE branch `$A7E3` and the practice text `$8A6E` run in `practice` (`work/docs/dfA/rec/practice`).

Witness: L1 11 (c1, c1g, controls, energy, energy-out, kempston, menu, practice).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings run into, not called (`stage1/kempston`, `stage1/energy`, `stage2/rec/energy-out` and 1 more) |
| Calls | `WipeInScreen`, `PutGlyph`, `TwoTone` |
| Reads | `$81FD` (`ControlMethod`); `$8E32`-`$8E33` (`RandomSeed`); `$9B7A`-`$9B7B` (`NamePointer`) |
| Writes | `$5921`-`$592C` (screen); `$5941`-`$594C` (screen); `$59C1`-`$59CC` (screen); `$5A01`-`$5A0C` (screen); `$81FD` (`ControlMethod`); `$8407` (`PracticeFlag`); 4 more ranges |
| Ports in | `$00FE`, `$EFFE`, `$F7FE` |

## panel

`src/game/panel.asm`

### `LoseLife` (`$866A`)

**A life lost: BOOM and the red screen, a life bar hollowed, the level again or GAME OVER**

From PassEnd (`$85C6`) when LifeLost `$8ED3` is set (the overload bar full `$A6F0`, or the energy drained `$A67C`).

SoundFlags = 0. When the COMPUTER line's MessageNumber `$A104` is below `$16`: message `$16` BOOM BOOM BOOM (MessageText = `$A15D`), PlaySound LifeLostSound, and the play area's 640 attributes (rows 0-19) = `$10` (black ink on red paper); then LoseLifeCount. With a message `$16` or above already shown (`$17` ENERGY DRAINED) LoseLifeDrained plays EnergyDrainedSound instead.

Run 45 times: `mine`, `overload`, `gameover` (the red screen, `$8675` 41 times) and `energy` (ENERGY DRAINED, `$869A` 4 times), and 36 lives lost over 26 RZX segments.

Witness: L1 56 (energy, energy-out, gameover, hof, mine, nameedit, overload, L45, L59, rzx x26).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 23 calls (`stage1/mine` 3, `stage1/overload` 3, `stage2/rec/energy-out` 3 and 8 more) |
| Called from | `PassEnd` (tail) |
| Calls | `PlaySound` |
| Reads | `$5800`-`$5A7E` (screen); `$837D` (`Lives`); `$8407` (`PracticeFlag`); `$8714`-`$87D3` (`GameOverBanner`); `$A104` (`MessageNumber`) |
| Writes | `$482A`-`$4835` (screen); `$484A`-`$4855` (screen); `$492A`-`$4935` (screen); `$494A`-`$4955` (screen); `$4A2A`-`$4A35` (screen); `$4A4A`-`$4A55` (screen); 17 more ranges |

### `LoseLifeDrained` (`$869A`)

**The energy drained: the falling sweep, then the life taken (LoseLifeCount)**

From LoseLife when MessageNumber is `$16` or above. PlaySound EnergyDrainedSound, then LoseLifeCount `$86A0`:

Not in practice: Lives `$837D` - 1, and the bar of that life (the new count n: columns 10 + 2n and 11 + 2n of row 21, lines 4-6) hollowed to `$40`, `$01` (its outline). Then 36 bursts of LifeLostSound, a Delay; lives left: SetUpLevel (the same level again); none: GAME OVER.

GAME OVER: GameOverBanner (96 x 16 pixels) at columns 10-21 of rows 9-10, its 24 attributes white (7); a buzz (`$A843` with HL = `$C814`: `$C8` x 256 loops of two speaker counters a period apart); TitleLoop.

Witness: L1 13 (energy, energy-out, hof, nameedit, rzx053912, rzx227686).

| | |
| --- | --- |
| Runs | ran within another entry's routine (reached by a jump or by running on, its calls below), no runs of its own counted |
| Calls | `TitleLoop` (tail), `SetUpLevel` (tail), `Delay`, `TwoTone`, `PlaySound` |

### `AddScore` (`$9AF3`)

**Add B tens to the score, then print it**

The score is ASCII digits in ScoreText (`$9B3E`-`$9B43`, the last a fixed "0": points come in tens). B times, the tens digit `$9B42` goes up by one with the carry to the left (a space counts as 0). Callers: the cells burnt (`$8F64`, B = `$18` or the value patched at `$8F63`), gremlins (`CursorFire` `$9A57`, 16 a gremlin), the receiver opening when the last cell is gone (`$85EC`, 25), the level's end bonuses (`$8808` one ten a step, `$884A` 50 a step: fragment 01). 21 897 runs over the 60 RZX segments. Falls into `PrintScore`.

Witness: L1 31837 (corner, ending, hof, nameedit, L x20, rzx x60).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 4,810 calls (`stage1/rzx/r045895` 153, `stage1/rzx/r183540` 151, `stage1/rzx/r340213` 151 and 80 more) |
| Called from | `PassEnd`, `LevelCompletePause`, `BeamStep`, `CursorFire` |
| Calls | `PrintScore` (falls into) |
| Reads | `$9B3D`-`$9B43` (`ScoreText+2`, `ScoreDigits`); `$D282`-`$D2CE` (`Font+130`) |
| Writes | `$53BA`-`$53BF` (screen); `$54BA`-`$54BF` (screen); `$55BA`-`$55BF` (screen); `$56BA`-`$56BF` (screen); `$57BA`-`$57BF` (screen); `$9B3E`-`$9B42` (`ScoreDigits`) |

### `PrintScore` (`$9B0A`)

**Print the score right-aligned on the panel**

From the last digit `$9B43` leftwards to the first space, right to left from `$53BF` (`PrintDigitsBack` `$9B10`). Called by `AddScore` and the level set-up (`$850C`).

Witness: L1 5012 (c1, c1g, cheat, controls, corner, ending, energy, energy-out, hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x60).

| | |
| --- | --- |
| Runs (c1g: the c1 recording's game window, from the jump to `$8382` (frame 15752 T 33930): the menu and play) | 1 call, 20 t-states own (0.00 %) |
| Runs (the other recordings) | 4,928 calls (`stage1/rzx/r045895` 154, `stage1/rzx/r183540` 154, `stage1/rzx/r340213` 152 and 87 more) |
| Called from | `SetUpLevel`, `AddScore` (falls into) |
| Calls | `PrintDigitsBack` (falls into) |

### `PrintDigitsBack` (`$9B10`)

**Print the characters at BC leftwards from screen address DE until a space**

Each character: rows 2-6 of its glyph (`$D202` + 8 x (character - 32)), five pixel rows down from DE; then DE one column left, BC one character back. Used for the score and the high score (`PrintHighScore` `$9B53`).

Witness: L1 33565 (c1, c1g, cheat, controls, corner, ending, energy, energy-out, hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x60).

| | |
| --- | --- |
| Runs (c1g: the c1 recording's game window, from the jump to `$8382` (frame 15752 T 33930): the menu and play) | 2 calls, 2,069 t-states own (0.00 %) |
| Runs (the other recordings) | 5,124 calls (`stage1/rzx/r183540` 157, `stage1/rzx/r045895` 155, `stage1/rzx/r340213` 153 and 87 more) |
| Called from | `PrintScore` (falls into), `PrintHighScore` (tail) |
| Reads | `$9B3D`-`$9B52` (`ScoreText+2`, `ScoreDigits`, `SavedScore`, `HighScoreText`); `$D282`-`$D2CE` (`Font+130`) |
| Writes | `$53BA`-`$53FF` (screen); `$54BA`-`$54FF` (screen); `$55BA`-`$55FF` (screen); `$56BA`-`$56BF` (screen); `$56FB`-`$56FF` (screen); `$57BA`-`$57BF` (screen); 1 more ranges |

### `ClearSavedScore` (`$9B30`)

**Clear the score kept at the level's start**

Five spaces at `$9B44`-`$9B48`: the level set-up (`$84EB`) copies them to the score digits `$9B3E`, so a new game or practice starts at 0. Called at a new game (`$842F`) and for practice (`$84DE`).

Witness: L1 13 (c1, c1g, controls, energy, energy-out, kempston, menu, practice, L01).

| | |
| --- | --- |
| Runs (c1g: the c1 recording's game window, from the jump to `$8382` (frame 15752 T 33930): the menu and play) | 1 call, 167 t-states own (0.00 %) |
| Runs (the other recordings) | 12 calls (`stage1/controls` 3, `docs/dfA/rec/practice` 2, `stage1/menu` 2 and 5 more) |
| Called from | `NewGameDelay2`, `SetUpLevel` |
| Writes | `$9B44`-`$9B48` (`SavedScore`) |

### `PrintHighScore` (`$9B53`)

**Print the hall of fame's top score on the panel as HIGH**

Copies the first score of the hall of fame (`$9FEE`, five digits, leading zeros turned to spaces) to `$9B4D`-`$9B51` and prints `$9B52` leftwards from `$53FF`. Called by the level set-up (`$850F`); 164 runs over all recordings.

Witness: L1 200 (c1, c1g, cheat, controls, energy, energy-out, hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x59).

| | |
| --- | --- |
| Runs (c1g: the c1 recording's game window, from the jump to `$8382` (frame 15752 T 33930): the menu and play) | 1 call, 228 t-states own (0.00 %) |
| Runs (the other recordings) | 196 calls (`stage1/menu` 61, `docs/integrate/rec/nameedit` 3, `stage1/controls` 3 and 87 more) |
| Called from | `SetUpLevel` |
| Calls | `PrintDigitsBack` (tail) |
| Reads | `$9FEE`-`$9FF2` (`HallOfFameScores+3`) |
| Writes | `$9B4D`-`$9B51` (`HighScoreText+3`) |

### `DrawPanel` (`$A50C`)

**The HUD panel: 1024 pixel bytes from `$7B80` to rows 20-23 and 128 attributes from `$7F80`**

DE = `$5080`, HL = `$7B80`: 32 bytes a pixel row, 8 rows a character row (D + 1 until bit 3 is set), then E + 32 for the next of the four character rows 20-23 (E = `$80`, `$A0`, `$C0`, `$E0`; done when it wraps to 0). Then 128 bytes to the attributes `$5A80-$5AFF`. So the picture at `$7B80` (the brief's OptionsPanel) is the play panel (LEVEL, LIVES, OVERLOAD, ENERGY, SCORE, HIGH, COMPUTER), 1024 + 128 bytes ending at `$7FFF`.

Called by `$8432` at each new game and level start. Evidence: 67 runs (`c1g`, `controls`, `energy`, `kempston`, `menu`, 59 RZX segments).

Witness: L1 92 (c1, c1g, controls, energy, energy-out, hof, kempston, menu, nameedit, practice, L x20, rzx x59).

| | |
| --- | --- |
| Runs (c1g: the c1 recording's game window, from the jump to `$8382` (frame 15752 T 33930): the menu and play) | 1 call, 34,836 t-states own (0.01 %) |
| Runs (the other recordings) | 91 calls (`stage1/controls` 3, `stage1/menu` 2, `stage1/rzx/r082057` 1 and 85 more) |
| Called from | `LevelPanel` |
| Reads | `$7B80`-`$7FFF` (`PanelPicture`) |
| Writes | `$5080`-`$51FF` (screen); `$5280`-`$52FF` (screen); `$5380`-`$53FF` (screen); `$5480`-`$54FF` (screen); `$5580`-`$55FF` (screen); `$5680`-`$56FF` (screen); 2 more ranges |

## beam

`src/game/beam.asm`

### `FindLaser` (`$8AC1`)

**Find the laser (`$47-$4A`) in the grid: the beam's start and direction, the cursor's first cell**

Scans the grid backwards from its last cell `$FDB9` (B = column + 1, C = row + 1) for a code `$47-$4A` (the laser; bit 7 clear). None: `$8378` = `$FF`, and MainLoop traces no beam.

Found: `$8374` = 2B, `$8375` = 2C (the laser's centre in half-cells); the direction `$8378` = 4 x ((code - `$43`) AND 3): `$47` east, `$48` down, `$49` west, `$4A` up. The direction's (dx, dy) from `$8170`: the beam's start `$8376` = x + dx and `$8377` = y + dy (the half-cell in front; it returns if that is off the field: x 32 or more, y 20 or more).

The cursor (`$96C3` column, `$96C4` row) starts on the cell in front of the laser and moves on by (dx / 2, dy / 2) until a cell is not empty: the cursor starts on the first element the laser points at (level 1: the mirror at row 7, column 0, left of the laser). The walk has no bound but the elements it meets.

From SetUpLevel (`$8547`).

Witness: L1 200 (c1, c1g, cheat, controls, energy, energy-out, hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x59).

| | |
| --- | --- |
| Runs (c1g: the c1 recording's game window, from the jump to `$8382` (frame 15752 T 33930): the menu and play) | 1 call, 2,241 t-states own (0.00 %) |
| Runs (the other recordings) | 196 calls (`stage1/menu` 61, `docs/integrate/rec/nameedit` 3, `stage2/rec/hof` 3 and 87 more) |
| Called from | `SetUpLevel` |
| Reads | `$8170`-`$8189` (`BeamDeltas`); `$96C3`-`$96C4` (`CursorVars`, `CursorY`); `$FD23`-`$FDB9` (`work space $FD23+`) |
| Writes | `$8374`-`$8378` (`HighlightX`, `HighlightY`, `BeamStartX`, `BeamStartY` and 1 more); `$96C3`-`$96C4` (`CursorVars`, `CursorY`) |

### `OpenReceiver` (`$8B3F`)

**The last cell burnt: the element in front of the receiver starts to explode (its door)**

From PassEnd (`$85E1`) when CellsLeft `$8380` reaches 0. Finds the receiver (`$4B-$4E`, scanning backwards like FindLaser); none: drops its return address and jumps to MainLoop (`$8B58`).

The receiver's direction (code - `$4B`) AND 3 gives (dx, dy) from `$8170`; the cell in front of it (x + dx, y + dy, returning if off the field) goes into the first explosion slot `$81B8` (grid address high, low, y, x), and CellsLeft = `$FF` (no second call); the door's own explosion then decrements it to `$FE` when its slot empties. PassEnd then explodes it like a burnt cell (the code `$57`, then `$58-$5C`, then empty).

In levels 1-60 the element in front of the receiver is a mine (`$41`, 23 levels), a wall (`$21-$3E`, 32), a block (4) or a fibre-optic end (`$53`, 1): the receiver is shut until every cell burns.

Run 21 times, all in RZX segments (once in each level the last cell burns).

Witness: L1 41 (L x20, rzx x21).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 41 calls (`stage1/rzx/r053912` 1, `stage1/rzx/r086376` 1, `stage1/rzx/r179716` 1 and 38 more) |
| Called from | `PassEnd` |
| Reads | `$8170`-`$8189` (`BeamDeltas`); `$FD23`-`$FDB9` (`work space $FD23+`) |
| Writes | `$81B8`-`$81BB` (`ExplosionSlots`); `$8380` (`CellsLeft`) |

### `TraceBeam` (`$8ED6`)

**Trace the beam from the laser: the step count cleared, then BeamStep until the beam ends**

From MainLoop (`$859B`) with BeamDirection, BeamX, BeamY at the laser's front. Clears BeamSteps and `$8EC0`, then BeamStep, which loops (through the step code's `JP $8EDD` at `$926A` / `$9274`) and returns when the beam ends.

BeamStep runs about 11.7 times a trace (1 038 316 against 88 519).

Witness: L1 112689 (c1, c1g, cheat, controls, corner, energy, energy-out, hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x59).

[Animation: `TraceBeam` at work](img/routines/TraceBeam.gif)

[Animation: `TraceBeam` at work, draw](img/routines/TraceBeam-draw.gif)

| | |
| --- | --- |
| Runs (c1g: the c1 recording's game window, from the jump to `$8382` (frame 15752 T 33930): the menu and play) | 1,012 calls, 30,360 t-states own (0.01 %) |
| Runs (the other recordings) | 110,903 calls (`stage2/rec/energy-out` 6,205, `stage1/energy` 6,171, `docs/integrate/rec/nameedit` 5,056 and 87 more) |
| Called from | `MainLoop` |
| Calls | `BeamStep` (falls into) |
| Reads | `$8170`-`$818F` (`BeamDeltas`); `$81B8`-`$81CC` (`ExplosionSlots`); `$8374`-`$8381` (`HighlightX`, `HighlightY`, `BeamStartX`, `BeamStartY` and 10 more); `$8914`-`$8917` (`CharMapPointer`, `PixelPointer`); `$8EBF`-`$8ED1` (`BeamSteps`, `BeamAtCentre`, `BeamReflected`, `BeamDirection` and 3 more); `$A8A6` (`SoundFlags`); 1 more ranges |
| Writes | `$81B8`-`$81CF` (`ExplosionSlots`); `$8374`-`$8375` (`HighlightX`, `HighlightY`); `$8914`-`$8917` (`CharMapPointer`, `PixelPointer`); `$8EBF`-`$8ED5` (`BeamSteps`, `BeamAtCentre`, `BeamReflected`, `BeamDirection` and 7 more); `$A8A6` (`SoundFlags`); `$E32F`-`$E33E` (`work space $E32F+`); 15 more ranges |

### `BeamStep` (`$8EDD`)

**One step of the beam: at a cell's centre, what the cell does to it; then the step code (`$906E`)**

BeamNextDirection = BeamDirection (`$FF`: return, the beam has ended). When BeamX or BeamY is odd the beam is between cells: on to `$906E`. Else the cell (row y/2 - 1, column x/2 - 1) at `$FD11` + 17 (y/2) + x/2 (= `$FD12` + 17 (row + 1) + column), BeamAtCentre = `$FF`, and the code with bit 7 cleared (a turning element acts as its current angle):

- `$00` empty: on (`$906E`);

- `$01-$10` a mirror: BeamMirror `$8FFB`;

- `$11-$20` a block: BeamAtCentre = 0, on (`$906E`, the step code decides);

- `$21-$3E` a wall: on (`$906E`, which reads BeamAtCentre);

- `$3F` (no level holds it), `$40` a cell: burnt (BeamBurn);

- `$41` a mine: BeamOnMine, the beam ends, SoundFlags bit 1 (BeamMine);

- `$42` the grey grid: `$9014` (a random scatter, the next annotator's);

- `$43-$4A` the laser (and `$43-$46`, which no level holds): BeamAtLaser `$8FAE`;

- `$4B-$4E` the receiver: BeamReceiver;

- `$4F-$57` the fibre optics: `$903E`;

- `$58` and up (a cell exploding): return, the beam ends.

Witness: L1 1251228 (c1, c1g, cheat, controls, corner, energy, energy-out, hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x59).

| | |
| --- | --- |
| Runs (c1g: the c1 recording's game window, from the jump to `$8382` (frame 15752 T 33930): the menu and play) | 13,658 calls, 3,657,123 t-states own (1.09 %) |
| Runs (the other recordings) | 1,170,175 calls (`stage1/rzx/r172483` 32,670, `stage2/rec/energy-out` 32,667, `stage1/energy` 32,429 and 82 more) |
| Called from | `TraceBeam` (falls into), `BeamMove` (tail) |
| Calls | `BeamAtLaser` (tail), `HighlightCell` (tail), `BeamMirror` (tail), `PrismTurn` (tail), `FibreEntry` (tail), `BeamVertex` (tail), `AddScore` |
| Reads | `$81B8`-`$81CC` (`ExplosionSlots`); `$8ECB`-`$8ECE` (`BeamDirection`, `BeamNextDirection`, `BeamX`, `BeamY`); `$A8A6` (`SoundFlags`); `$FD11`-`$FDCB` (`work space $FD11+`) |
| Writes | `$81B8`-`$81CF` (`ExplosionSlots`); `$8374`-`$8375` (`HighlightX`, `HighlightY`); `$8EC1`-`$8ED4` (`BeamAtCentre`, `BeamReflected`, `BeamDirection`, `BeamNextDirection` and 5 more); `$A8A6` (`SoundFlags`) |

### `BeamAtLaser` (`$8FAE`)

**The beam at the laser: from its front, BeamBackToLaser; else the beam ends**

From BeamStep (`$8F2F`) for the codes `$43-$4A`. As BeamReceiver: B = (code - `$43`) AND 3 (the laser's facing); the beam must run on an axis and against that facing (((direction + 8) AND 12) / 4 = B), else return: the beam ends against the laser's side or back. Then falls into BeamBackToLaser.

Run 1094 times in 18 RZX segments; the front test passed 89 times (`$8FBA`, 7 segments).

Witness: L1 1135 (L x10, rzx x18).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 116 calls (`stage1/rzx/r082057` 116) |
| Called from | `BeamStep` (tail) |
| Calls | `BeamBackToLaser` (falls into) |
| Reads | `$8ECB` (`BeamDirection`) |

### `BeamBackToLaser` (`$8FC5`)

**BeamInLaser = `$FF`, then HighlightCell on the laser's cell**

From BeamAtLaser and from the step code (`$91B5`, `$926E` the 40th step, `$93D9`, `$9438`, `$9657`, `$96A4`, `$96B9`). HighlightCell uses `$8374` / `$8375`, the laser's centre FindLaser left there (BeamReceiver changes them only at contact, which ends the level).

6521 runs: `mine`, `overload` and 54 RZX segments. The `overload` recording sets BeamInLaser by a POKE (WALKTHROUGH 6.0).

Witness: L1 7109 (hof, mine, nameedit, overload, L x20, rzx x54).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 7,019 calls (`stage1/rzx/r295329` 350, `stage1/rzx/r268227` 334, `stage1/rzx/r090631` 282 and 71 more) |
| Called from | `BeamAtLaser` (falls into), `BeamVertex` (tail), `BeamMove`, `BeamReflectIn` (tail), `BeamReflectOut` (tail) |
| Calls | `HighlightCell` (falls into) |
| Reads | `$8374`-`$8375` (`HighlightX`, `HighlightY`) |
| Writes | `$8ED5` (`BeamInLaser`); `$E321`-`$E35E` (`work space $E321+`); `$E377`-`$E37E` (`work space $E377+`); `$E397`-`$E3A2` (`work space $E397+`); `$E3C1`-`$E3C2` (`work space $E3C1+`); `$E3EF`-`$E3F0` (`work space $E3EF+`); 17 more ranges |

### `HighlightCell` (`$8FCA`)

**Colour the cell at (`$8374`, `$8375`) bright magenta (`$43`) in ColourBuffer and mark it twice**

The cell whose centre is x = `$8374`, y = `$8375` (half-cells): its four colours at ColourBuffer `$E600` + 32 (y - 1) + x - 1 = `$43` (bright magenta on black), its four DrawMarks = 2. CopyPlayArea copies the colours every pass, so the cell shows magenta until DrawMarkedChars draws its characters again with their own colours (the next pass, as the mark is still 1).

From BeamReceiver (`$8FAC`) and BeamBackToLaser. 6539 runs.

Witness: L1 7147 (hof, mine, nameedit, overload, L x20, rzx x55).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 2,814 calls (`stage1/rzx/r090631` 283, `stage1/rzx/r086376` 258, `stage1/rzx/r286796` 255 and 30 more) |
| Called from | `BeamStep` (tail), `BeamBackToLaser` (falls into) |
| Reads | `$8374`-`$8375` (`HighlightX`, `HighlightY`) |
| Writes | `$E321`-`$E370` (`work space $E321+`); `$E385`-`$E390` (`work space $E385+`); `$E3A1`-`$E3A2` (`work space $E3A1+`); `$E3C1`-`$E3C2` (`work space $E3C1+`); `$E3ED`-`$E3EE` (`work space $E3ED+`); `$E40D`-`$E40E` (`work space $E40D+`); 20 more ranges |

### `BeamMirror` (`$8FFB`)

**A mirror: BeamNextDirection = (code - 1 - BeamDirection + 8) AND 15, BeamReflected; on to `$906E`**

C = code - 1, the mirror's angle 0-15 (`$01` upright: an east beam goes back west; `$05` an east beam goes up; `$09` lies along the east-west axis). The new direction is (16 - direction + C + 8) AND 15: the reflection of the beam in a mirror line turned C x 11.25 degrees from upright. BeamReflected = `$FF`; then `$906E`.

From BeamStep (`$8F1A`).

Witness: L1 218110 (c1, c1g, cheat, controls, energy, energy-out, hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x58).

| | |
| --- | --- |
| Runs (c1g: the c1 recording's game window, from the jump to `$8382` (frame 15752 T 33930): the menu and play) | 1,012 calls, 98,392 t-states own (0.03 %) |
| Runs (the other recordings) | 211,797 calls (`stage1/rzx/r146186` 7,058, `stage1/rzx/r254939` 6,252, `stage2/rec/energy-out` 6,205 and 82 more) |
| Called from | `BeamStep` (tail) |
| Calls | `BeamVertex` (tail) |
| Reads | `$8ECB` (`BeamDirection`) |
| Writes | `$8EC2`-`$8ECC` (`BeamReflected`, `BeamDirection`, `BeamNextDirection`) |

### `PrismTurn` (`$9014`)

**The prism (`$42`): the beam leaves in a random direction, up to four sixteenths either side**

Jumped to by the trace `$8EDD` (at `$8F34`) when the vertex is the centre of a prism cell (code `$42`, the grey grid). It takes a 16-bit number from the generator `$8E15` (HL) and turns the beam: when bit 7 of H is set the new direction `$8ECC` = (direction `$8ECB` + 4 - (H AND 7)) AND 15, else (direction - 4 + (H AND 7)) AND 15, so the beam leaves 4 to 12 sixteenths off its reverse, never straight back: 4 and 12 sixteenths away from the arrival come from one case each, the seven between from both.

It skips the drawing of this vertex (`BeamVertex` `$906E`) and goes straight to the move `$9226`: the beam is not drawn over the prism's centre. A prism is turned anew on every pass of the trace, so its beam flickers from pass to pass (the generator advances on every call).

Experiment: `work/ann/02-beam/prism.py` puts a prism in the beam of level 1 (`play0.bin`, the beam arriving westwards, direction 8) and traces with 64 seeds of `$8E32`: the beam leaves in the directions 4-12 only.

Witness: L1 16015 (L x8, rzx x20).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 10,204 calls (`stage1/rzx/r107497` 2,446, `stage1/rzx/r118129` 1,948, `stage1/rzx/r286796` 1,224 and 21 more) |
| Called from | `BeamStep` (tail) |
| Calls | `Random`, `BeamNewDirection` (tail) |
| Reads | `$8ECB` (`BeamDirection`) |
| Writes | `$8ECC` (`BeamNextDirection`) |

### `FibreEntry` (`$903E`)

**A fibre-optic end (`$4F-$57`): find the paired end and arm the jump to it**

Jumped to by the trace `$8EDD` (at `$8F26`) with A = the cell code (`$4F`-`$57`, bit 7 cleared) at the centre of a fibre-optic cell. The pair of an end is the code with bit 0 flipped (`$50`/`$51`, `$52`/`$53`, `$54`/`$55`, `$56`/`$57`; each level holds each code at most once). `$8ED1` = 2 marks the entry.

The search runs backwards over the level grid from its last cell `$FDB9` (row 8, column 14), 9 rows of 15 cells, skipping the two guard bytes of each 17-byte row. Found: the partner's vertex is kept in `$8ECF` (x = 2 x column + 2) and `$8ED0` (y = 2 x row + 2), the centre of its cell in the trace's character units. Then the vertex is drawn (`$906E`), and at its end (`$91C6`) the beam is moved to the partner and leaves it in its arrival direction. Not found: the beam stops here (`$8ECC` = `$FF`; known only from the code, no level lacks a partner).

Experiment: `work/ann/02-beam/elements.py 50 7 1 51 2 5` (a `$50` in the beam of level 1, its `$51` at row 2 column 5): the beam enters at x 4 y 16 going west and leaves the partner at x 12 y 6 going west.

Witness: L1 4105 (L x6, rzx x15).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 4,028 calls (`stage1/rzx/r146186` 993, `stage1/rzx/r136166` 488, `stage1/rzx/r053912` 432 and 17 more) |
| Called from | `BeamStep` (tail) |
| Calls | `BeamVertex` (falls into) |
| Reads | `$FD26`-`$FDB9` (`work space $FD26+`) |
| Writes | `$8ECF`-`$8ED1` (`BeamY+1`) |

### `BeamVertex` (`$906E`)

**Draw the beam round one vertex in three passes, then take the outgoing direction**

The heart of the beam: reached from the trace `$8EDD` for every vertex once the cell at the vertex (if any) has set the outgoing direction `$8ECC` (= the incoming one by default), and from the fibre jump and the slanted wall reflection (`$96B5`). A vertex is a corner of four characters of the play area, x = `$8ECD` (0-`$20`), y = `$8ECE` (0-`$14`); the centre of the cell at column c, row r is x = 2c + 2, y = 2r + 2.

It clears the per-vertex flags `$8EC3`-`$8EC8`, stops the trace (`$8ECC` = `$FF`) on the play area's edge (x 0 or `$20`, y 0 or `$14`: the vertex is still drawn), and keeps two pointers to the character up and left of the vertex: `$8914` into the character map `$E000` (`$DFDF` + 32y + x) and `$8916` into the pixel buffer `$E900` (`$E7FF` + 256y + x).

The glyphs come from the table `$8000`: four bytes for each direction and set (E = 4 x direction + `$8381`, D = `$80`; `$8381` is `$40` on the flashing frames of the warning set by `$A623`), one byte for each of the four characters round the vertex (up-left, up-right, down-left, down-right). Bits 7-6 of the byte say which pass draws it, bits 5-0 are the glyph (`$D500` + 8 x glyph): 00 the incoming pass `BeamInChar` `$9278`, bit 7 the corner pass `BeamCornerChar` `$9440` (the characters a slanted beam cuts through a corner), bit 6 the outgoing pass `BeamOutChar` `$94FD`.

1. The incoming pass with the incoming direction `$8ECB` (none when it is `$FF`: after a fibre jump or a wall's turn). 2. The corner pass with the same bytes, but only for the characters inside the play area. 3. When the new direction is the reverse of the incoming one (a mirror at right angles, a wall hit head on), the beam goes back into the laser: `$8FC5` (OVERLOAD, `$8ED5` = `$FF`) and the trace ends. 4. At a fibre entry (`$8ED1` = 2) the vertex moves to the partner's (`$91C6`) and the vertex is drawn again with no incoming pass. 5. The outgoing pass with the new direction, then the move (`BeamStep` `$9226`).

Any pass may end the trace on a wall or an absorbing polariser (its handler drops the return addresses and returns from the trace). 1 046 773 vertices drawn over all recordings (c1g, controls, energy, kempston, menu, mine, overload and the 59 RZX level segments).

Witness: L1 1276460 (c1, c1g, cheat, controls, corner, energy, energy-out, hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x59).

| | |
| --- | --- |
| Runs (c1g: the c1 recording's game window, from the jump to `$8382` (frame 15752 T 33930): the menu and play) | 13,784 calls, 25,765,186 t-states own (7.67 %) |
| Runs (the other recordings) | 1,196,939 calls (`stage1/rzx/r172483` 33,901, `stage2/rec/energy-out` 32,667, `stage1/energy` 32,429 and 82 more) |
| Called from | `BeamStep` (tail), `BeamMirror` (tail), `FibreEntry` (falls into), `BeamReflectOut` (tail) |
| Calls | `BeamBackToLaser` (tail), `BeamInChar`, `BeamCornerChar`, `BeamOutChar` |
| Reads | `$8170`-`$818F` (`BeamDeltas`); `$8381` (`BeamGlyphSet`); `$8914`-`$8917` (`CharMapPointer`, `PixelPointer`); `$8EBF`-`$8ED1` (`BeamSteps`, `BeamAtCentre`, `BeamReflected`, `BeamDirection` and 3 more) |
| Writes | `$8914`-`$8917` (`CharMapPointer`, `PixelPointer`); `$8EBF`-`$8ED1` (`BeamSteps`, `BeamAtCentre`, `BeamReflected`, `BeamDirection` and 3 more) |

### `BeamNewDirection` (`$9226`)

**Take the new direction and move the beam to its next vertex**

Falls in from `BeamVertex` `$906E`, and is jumped to by `PrismTurn` `$9014`. The new direction `$8ECC` becomes the direction `$8ECB`; `$FF` ends the trace. HL = the step of the direction in the table `$8170` (two bytes a direction, dx then dy: `$02,$00` for 0 (east), `$02,$01`, `$01,$01`, `$01,$02`, `$00,$02` for 4 (south), and so on round to `$02,$FF` for 15): a step is one cell (two characters) along the axes, a character on the diagonals, and two by one on the eight slopes between, so the 16 directions are 22.5 degrees apart only roughly (26.6 and 63.4 degrees for the slopes).

Falls into `BeamMove` `$9235`.

Witness: L1 1108934 (c1, c1g, cheat, controls, corner, energy, energy-out, hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x59).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 10,204 calls (`stage1/rzx/r107497` 2,446, `stage1/rzx/r118129` 1,948, `stage1/rzx/r286796` 1,224 and 21 more) |
| Called from | `PrismTurn` (tail) |
| Calls | `BeamMove` (falls into) |
| Reads | `$8170`-`$818F` (`BeamDeltas`); `$8EBF`-`$8ECE` (`BeamSteps`, `BeamAtCentre`, `BeamReflected`, `BeamDirection` and 3 more) |
| Writes | `$8EBF`-`$8ECE` (`BeamSteps`, `BeamAtCentre`, `BeamReflected`, `BeamDirection` and 3 more) |

### `BeamMove` (`$9235`)

**Move the vertex by the step at HL, count the beam's length, trace on**

Entered from `BeamNewDirection` (the step of the direction) and from the reflections of `BeamReflectIn` `$938F` with HL at a step of their own tables (`$8140`, `$8100`). x + dx must stay below `$21` and y + dy below `$15` (a negative result is above too): else the trace ends.

The length `$8EBF` counts the steps, the diagonal ones (directions 2, 6, 10, 14, one character a step) only when the new x is odd, so it counts about one a cell. At a length of 40 (`$28`) the trace calls `$8FC5`: OVERLOAD (`$8ED5` = `$FF`) as if the beam had come back into the laser, and the laser lit; the trace still goes on, up to 150 (`$96`) steps, then stops. So a beam longer than 40 cells overloads the laser on every pass (the RZX segments reach 40 in 14 of the 59 level segments, `$926D` 2010 runs in all).

Then back to the trace `$8EDD` for the next vertex.

Witness: L1 1139437 (c1, c1g, cheat, controls, corner, energy, energy-out, hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x59).

| | |
| --- | --- |
| Runs (c1g: the c1 recording's game window, from the jump to `$8382` (frame 15752 T 33930): the menu and play) | 12,646 calls, 2,655,869 t-states own (0.79 %) |
| Runs (the other recordings) | 699,850 calls (`stage1/rzx/r172483` 31,573, `stage1/rzx/r004833` 28,063, `stage1/rzx/r268227` 25,565 and 42 more) |
| Called from | `BeamNewDirection` (falls into), `BeamReflectIn` (tail) |
| Calls | `BeamStep` (tail), `BeamBackToLaser` |
| Reads | `$8144`-`$818F` (`InBounceTable+4`, `BeamDeltas`); `$8EBF`-`$8ECE` (`BeamSteps`, `BeamAtCentre`, `BeamReflected`, `BeamDirection` and 3 more) |
| Writes | `$8EBF`-`$8ECE` (`BeamSteps`, `BeamAtCentre`, `BeamReflected`, `BeamDirection` and 3 more) |

### `BeamInChar` (`$9278`)

**The incoming pass: one character round the vertex, its glyph, the walls and the polarisers it meets**

Called four times by `BeamVertex` `$906E` with DE at the glyph byte of the character (`$8000` table) and `$8914` / `$8916` at the character. A byte with bit 7 or 6 set is not this pass's: nothing drawn, only the colour of the next step (`BeamInNext` `$92DE`). `$8EC4` counts the characters of this pass (1-4).

At a cell's centre (`$8EC1` set by the trace, not for polarisers) only the walls count: `$71` absorbs (`BeamAbsorbIn` `$9344`), `$72` reflects (`BeamReflectIn` `$938F`), anything else is drawn over: the beam crosses the element's own characters. Elsewhere, by the character in the map: 0 drawn; `$01`-`$30` (a mirror's art) and `$7C`-`$7F` (a prism's), `$B0` and up (fibre ends, the explosion) not drawn; `$31`-`$70` a polariser (`$92FD`); `$71` absorbs, `$72` reflects; `$73`-`$7B` (cells, mines) drawn; `$80`-`$AF` (the laser, the receiver) absorb.

Witness: L1 4870383 (c1, c1g, cheat, controls, corner, energy, energy-out, hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x59).

| | |
| --- | --- |
| Runs (c1g: the c1 recording's game window, from the jump to `$8382` (frame 15752 T 33930): the menu and play) | 53,746 calls, 20,924,389 t-states own (6.23 %) |
| Runs (the other recordings) | 4,780,310 calls (`stage2/rec/energy-out` 130,668, `stage1/energy` 129,716, `stage1/rzx/r172483` 129,173 and 87 more) |
| Called from | `BeamVertex` |
| Calls | `BeamPlotGlyph` (falls into), `BeamInNext` (tail), `BeamAbsorbIn` (tail), `BeamReflectIn` (tail) |
| Reads | `$8000`-`$807F` (`BeamGlyphBytes`); `$8143`-`$816D` (`InBounceTable+3`); `$8190`-`$81B7` (`GrazeOffsets`, `PolariserCells`); `$8914`-`$8917` (`CharMapPointer`, `PixelPointer`); `$8EC1`-`$8ED1` (`BeamAtCentre`, `BeamReflected`, `BeamDirection`, `BeamNextDirection` and 2 more); `$D508`-`$D51F` (`BeamGlyphs+8`); 4 more ranges |
| Writes | `$8EC3`-`$8ECB` (`BeamReflected+1`, `BeamDirection`); `$E300`-`$E57F` (`work space $E300+`); `$E600`-`$E87F` (`work space $E600+`); `$E900`-`$FCFF` (`work space $E900+`) |

### `BeamPlotGlyph` (`$92B3`)

**Draw a beam glyph into the pixel buffer: mark the character and colour it**

Falls in from `BeamInChar` `$9278`, jumped to by the polariser's pass `$9341`. The character gets the draw mark 2 (`$E300`, so `$8A09` copies it) and the colour `$43` (bright magenta on black, `$E600`); the glyph C (`$D500` + 8C) is ORed into the eight pixel rows at `$8916`, whose address is kept in `$8EC9`: a wall met at the next character of the pass erases it (`$9381`).

Falls into `BeamInNext` `$92DE`.

Witness: L1 1533825 (c1, c1g, cheat, controls, corner, energy, energy-out, hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x59).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 191,589 calls (`stage1/rzx/r053912` 30,118, `stage1/rzx/r227686` 29,051, `stage1/rzx/r204297` 26,361 and 8 more) |
| Called from | `BeamInChar` (falls into), `BeamInNext` (tail) |
| Calls | `BeamInNext` (falls into) |
| Reads | `$8916`-`$8917` (`PixelPointer`); `$D508`-`$D51F` (`BeamGlyphs+8`); `$D530`-`$D597` (`BeamGlyphs+48`); `$D5B8`-`$D637` (`BeamGlyphs+184`); `$E900`-`$FCFD` (`work space $E900+`) |
| Writes | `$8EC9`-`$8ECA` (`BeamReflected+7`); `$E300`-`$E57D` (`work space $E300+`); `$E600`-`$E87D` (`work space $E600+`); `$E900`-`$FCFD` (`work space $E900+`) |

### `BeamInNext` (`$92DE`)

**The next glyph byte; light the character on a mirror or at a fibre entry**

The common end of the incoming pass (`BeamInChar` `$9278`, `BeamPlotGlyph`, the walls when they let the beam by). DE moves to the next glyph byte. When the vertex is the centre of a mirror (`$8EC2` set by `$8FFB`) the character is coloured `$43` and marked: the mirror the beam bounces off lights up in the beam's colour. At a fibre entry (`$8ED1` = 2) it takes `$7B` (bright, white paper, magenta ink).

The entry point `$92FD` is the polariser: the polariser's angle is (character - `$31`) AND `$1F` / 4 (eight angles, four characters each, `$31`-`$50` the cyan ones of cells `$11`-`$18`, `$51`-`$70` the yellow ones of `$19`-`$20`). A beam whose direction AND 7 is the angle (along its axis, either way) passes: three more characters round the cell get the mark and the colour (offsets `$81A0`, six bytes for each of the four characters) and the glyph is drawn. Otherwise a cyan polariser absorbs (`BeamAbsorbIn`) and a yellow one reflects (`BeamReflectIn`).

Experiment (`elements.py`, the beam going west through row 7 column 1 of level 1): `$11` and `$19` (angle 0) pass it, `$13` (angle 2) absorbs it, `$1B` (angle 2) sends it back into the laser (OVERLOAD).

Witness: L1 4831391 (c1, c1g, cheat, controls, corner, energy, energy-out, hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x59).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1,993,905 calls (`stage1/rzx/r172483` 127,439, `stage1/rzx/r004833` 115,079, `stage1/rzx/r227686` 100,880 and 25 more) |
| Called from | `BeamInChar` (tail), `BeamPlotGlyph` (falls into), `BeamAbsorbIn` (tail), `BeamReflectIn` (tail) |
| Calls | `BeamPlotGlyph` (tail), `BeamReflectIn` (tail) |
| Reads | `$8914`-`$8915` (`CharMapPointer`); `$8EC2`-`$8ED1` (`BeamReflected`, `BeamDirection`, `BeamNextDirection`, `BeamX` and 1 more) |
| Writes | `$E321`-`$E55E` (`work space $E321+`); `$E621`-`$E85E` (`work space $E621+`) |

### `BeamAbsorbIn` (`$9344`)

**The incoming beam meets an absorbing wall (`$71`), a cyan polariser across it, the laser or the receiver**

From `BeamInChar` `$9278` and the polariser test `$92FD`. A beam on the slopes or diagonals (direction AND 3 not 0) is absorbed at once. A beam along an axis, at its first wall character of the vertex (`$8EC3`), runs between two characters: the one across the beam from this one (offsets `$8190`, one word for each character and axis) must be a wall or a polariser too (`$31`-`$72`), else the beam grazes the wall's side and goes on (`BeamInNext`). When it is, and this is not the first character of the pass, the glyph drawn last (`$8EC9`) is wiped with the blank character `$D700`.

Absorbed: the two return addresses are dropped and the trace returns to MainPass: the beam ends here.

Experiment (`elements.py`): a full absorbing wall `$2F` ends the beam (`absorb-in`); a single quarter `$21` is grazed and the beam goes on.

Witness: L1 9309 (c1, c1g, L x10, rzx x29).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 4,125 calls (`stage1/rzx/r239803` 1,182, `stage1/rzx/r107497` 1,128, `stage1/rzx/r311752` 605 and 16 more) |
| Called from | `BeamInChar` (tail) |
| Calls | `BeamInNext` (tail) |
| Reads | `$8190`-`$819D` (`GrazeOffsets`); `$8EC3`-`$8ECB` (`BeamReflected+1`, `BeamDirection`); `$E045` (`work space $E045+`); `$E05A` (`work space $E05A+`); `$E0D0` (`work space $E0D0+`); `$E104`-`$E10C` (`work space $E104+`); 8 more ranges |
| Writes | `$8EC3` (`BeamReflected+1`) |

### `BeamReflectIn` (`$938F`)

**The incoming beam meets a reflecting wall (`$72`) or a yellow polariser across it**

From `BeamInChar` `$9278` and the polariser test `$92FD`. Along an axis the test is the absorbing wall's (`$9344`): grazed when the character across is free; else the beam goes straight back, which is the laser's OVERLOAD (`$8FC5`), and the trace ends (the second wall character of a vertex too).

On a slope or diagonal it bounces (`$93DC`): the table `$8140` (three bytes a direction: the new direction, dx, dy) gives a slope's mirror image off the wall it can meet (1, 7, 9, 15 off an upright wall: 1 to 7, 7 to 1, 9 to 15, 15 to 9; 3, 5, 11, 13 off a level one: 3 to 13 and so on) and the step to the vertex it leaves from; a diagonal (bit 7 of the first byte) reads `$8100` + 16 x n: two words, the characters above and to the side of the corner, and four answers by which of them are walls: none or both send it back (the trace then sees the reverse direction and OVERLOADs), one turns it a quarter. If the new direction is the reverse: OVERLOAD. Then `BeamMove` `$9235` with that step.

The diagonal branch `$93F2` ran in no play, only on the clone `corner` (InCornerTable `$8100`); the slope branch ran 21 949 times in 33 RZX segments.

Experiment (`elements.py`): a full reflecting wall `$3E` and a yellow polariser across the beam (`$1B`) send the westward beam of level 1 straight back: `$8ED5` = `$FF`.

Witness: L1 35456 (c1, c1g, cheat, corner, hof, nameedit, L x9, rzx x33).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 26,076 calls (`docs/integrate/rec/nameedit` 2,944, `stage2/rec/hof` 2,944, `stage1/rzx/r172483` 2,140 and 26 more) |
| Called from | `BeamInChar` (tail), `BeamInNext` (tail) |
| Calls | `BeamBackToLaser` (tail), `BeamMove` (tail), `BeamInNext` (tail) |
| Reads | `$8143`-`$816D` (`InBounceTable+3`); `$8190`-`$819F` (`GrazeOffsets`); `$8EC3`-`$8ECB` (`BeamReflected+1`, `BeamDirection`); `$E027`-`$E02E` (`work space $E027+`); `$E048`-`$E0F2` (`work space $E048+`); `$E106`-`$E218` (`work space $E106+`); 1 more ranges |
| Writes | `$8EC3`-`$8ECB` (`BeamReflected+1`, `BeamDirection`) |

### `BeamCornerChar` (`$9440`)

**The corner pass: the characters a slanted beam cuts through at a corner**

Called up to four times by `BeamVertex` `$906E` (the characters inside the play area) with DE at the glyph byte; only bytes with bit 7 set are this pass's (the slopes and diagonals: the beam crosses the corner of a character beside the vertex). Its glyph (bit 7 cleared) is ORed into the pixel buffer with the mark 2 and, on an empty character, the colour `$43`.

By the character: 0 drawn and lit; `$01`-`$30` (mirrors) and `$7C` and up not drawn; a polariser (`$949C`) along the beam's axis is drawn only when the character is already lit (`$E600` = `$43`); across it, a cyan polariser's character counts as an absorbing corner and a yellow one's as a reflecting corner; `$71` and `$72` corners (`$94C4`, `$94D9`): the first one is passed; a second absorbing corner ends the beam; two corners of which one reflects turn it by the fourth byte of the direction's row of `$8080` (`$94E9`), mostly straight back (the OVERLOAD of `$91A9`). At a cell's centre (`$8EC1`) walls only, as in the incoming pass.

Witness: L1 4597599 (c1, c1g, cheat, controls, corner, energy, energy-out, hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x59).

| | |
| --- | --- |
| Runs (c1g: the c1 recording's game window, from the jump to `$8382` (frame 15752 T 33930): the menu and play) | 47,544 calls, 18,948,800 t-states own (5.64 %) |
| Runs (the other recordings) | 4,517,137 calls (`stage1/rzx/r172483` 121,811, `stage2/rec/energy-out` 118,258, `stage1/energy` 117,373 and 87 more) |
| Called from | `BeamVertex` |
| Reads | `$8000`-`$80D7` (`BeamGlyphBytes`, `OutBounceTable`); `$80EF`-`$80FF` (`OutBounceTable+111`); `$8914`-`$8917` (`CharMapPointer`, `PixelPointer`); `$8EC1`-`$8ECB` (`BeamAtCentre`, `BeamReflected`, `BeamDirection`); `$D500`-`$D507` (`BeamGlyphs`); `$D520`-`$D52F` (`BeamGlyphs+32`); 7 more ranges |
| Writes | `$8EC5`-`$8ECC` (`BeamReflected+3`, `BeamDirection`, `BeamNextDirection`); `$E300`-`$E57F` (`work space $E300+`); `$E600`-`$E87F` (`work space $E600+`); `$E900`-`$FCFF` (`work space $E900+`) |

### `BeamOutChar` (`$94FD`)

**The outgoing pass: one character round the vertex in the new direction**

Called four times by `BeamVertex` (at `$91EA`) with DE at the glyph byte of the new direction; only bytes with bit 6 set are this pass's (the half of the beam that leaves the vertex). `$8EC8` counts its characters. The tests mirror the incoming pass's (`BeamInChar` `$9278`): at a cell's centre only the walls; elsewhere 0 drawn, mirrors' and prisms' characters skipped, polarisers (`$957A`), `$71` and the laser / receiver characters absorb (`BeamAbsorbOut` `$95C2`), `$72` reflects (`BeamReflectOut` `$960D`). The polariser test compares the direction `$8ECB`, not the new one `$8ECC`; after a bounce in place (`$96A7`) `$8ECB` is `$FF`, so a polariser's character beside that vertex is judged as if the beam ran at angle 7 (known only from the code).

Witness: L1 4498406 (c1, c1g, cheat, controls, corner, energy, energy-out, hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x59).

| | |
| --- | --- |
| Runs (c1g: the c1 recording's game window, from the jump to `$8382` (frame 15752 T 33930): the menu and play) | 47,670 calls, 17,155,368 t-states own (5.11 %) |
| Runs (the other recordings) | 4,418,477 calls (`stage1/rzx/r172483` 122,970, `stage1/rzx/r004833` 111,650, `stage2/rec/energy-out` 105,848 and 87 more) |
| Called from | `BeamVertex` |
| Calls | `BeamOutPlot` (falls into), `BeamOutNext` (tail), `BeamAbsorbOut` (tail), `BeamReflectOut` (tail) |
| Reads | `$8000`-`$80FE` (`BeamGlyphBytes`, `OutBounceTable`); `$8190`-`$81B7` (`GrazeOffsets`, `PolariserCells`); `$8914`-`$8917` (`CharMapPointer`, `PixelPointer`); `$8EC0`-`$8ED1` (`BeamSteps+1`, `BeamAtCentre`, `BeamReflected`, `BeamDirection` and 3 more); `$D508`-`$D51F` (`BeamGlyphs+8`); `$D530`-`$D597` (`BeamGlyphs+48`); 3 more ranges |
| Writes | `$8EC0`-`$8ECC` (`BeamSteps+1`, `BeamAtCentre`, `BeamReflected`, `BeamDirection` and 1 more); `$E300`-`$E57F` (`work space $E300+`); `$E600`-`$E87F` (`work space $E600+`); `$E900`-`$FCFF` (`work space $E900+`) |

### `BeamOutPlot` (`$9538`)

**Draw an outgoing glyph: mark, colour `$43`, OR the glyph in**

As `BeamPlotGlyph` `$92B3` for the outgoing pass (glyph = the byte with bit 6 cleared); the pixel address is kept in `$8EC9`. Falls into `BeamOutNext` `$9565`.

Witness: L1 1357897 (c1, c1g, cheat, controls, corner, energy, energy-out, hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x59).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 86,067 calls (`stage1/rzx/r227686` 27,794, `stage1/rzx/r204297` 24,847, `stage1/rzx/r063909` 23,051 and 1 more) |
| Called from | `BeamOutChar` (falls into), `BeamOutNext` (tail) |
| Calls | `BeamOutNext` (falls into) |
| Reads | `$8916`-`$8917` (`PixelPointer`); `$D508`-`$D51F` (`BeamGlyphs+8`); `$D530`-`$D597` (`BeamGlyphs+48`); `$D5B8`-`$D5C7` (`BeamGlyphs+184`); `$D5D8`-`$D61F` (`BeamGlyphs+216`); `$D630`-`$D637` (`BeamGlyphs+304`); 1 more ranges |
| Writes | `$8EC9`-`$8ECA` (`BeamReflected+7`); `$E300`-`$E57A` (`work space $E300+`); `$E600`-`$E87A` (`work space $E600+`); `$E900`-`$FCFA` (`work space $E900+`) |

### `BeamOutNext` (`$9565`)

**The next outgoing glyph byte; at a fibre end colour the character `$7B`**

The common end of the outgoing pass. While `$8ED1` is not 0 (a fibre entry, 2, or the partner end after the jump, 1) the character gets the colour `$7B`. The entry point `$957A` is the outgoing pass's polariser: passes along the axis (three characters marked through `$81A0`, then `BeamOutPlot`), else cyan absorbs, yellow reflects.

Witness: L1 4448984 (c1, c1g, cheat, controls, corner, energy, energy-out, hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x59).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1,270,483 calls (`stage1/rzx/r172483` 121,548, `stage1/rzx/r004833` 110,852, `stage1/rzx/r227686` 99,203 and 14 more) |
| Called from | `BeamOutChar` (tail), `BeamOutPlot` (falls into), `BeamAbsorbOut` (tail), `BeamReflectOut` (tail) |
| Calls | `BeamOutPlot` (tail), `BeamReflectOut` (tail) |
| Reads | `$8914`-`$8915` (`CharMapPointer`); `$8ED1` (`BeamY+3`) |
| Writes | `$E329`-`$E378` (`work space $E329+`); `$E389`-`$E398` (`work space $E389+`); `$E3B3`-`$E3B4` (`work space $E3B3+`); `$E3D3`-`$E3D4` (`work space $E3D3+`); `$E42D`-`$E456` (`work space $E42D+`); `$E47D`-`$E47E` (`work space $E47D+`); 18 more ranges |

### `BeamAbsorbOut` (`$95C2`)

**The outgoing beam meets an absorbing wall, a cyan polariser across it, the laser or the receiver**

As `BeamAbsorbIn` `$9344` with the new direction `$8ECC` and the pass's count `$8EC8`: along an axis the character across (`$8190`) must be a wall too, else the beam grazes it; then the last glyph (`$8EC9`) is wiped unless this is the pass's first character, and the trace ends. On a slope or a diagonal: absorbed at once.

Experiment (`elements.py 21`): a quarter wall `$21` at the up-left of the cell is reached here and grazed; the beam goes on west.

Witness: L1 5864 (c1, c1g, practice, L x17, rzx x36).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 2,352 calls (`docs/dfA/rec/practice` 582, `stage1/rzx/r327592` 558, `stage1/rzx/r107497` 276 and 28 more) |
| Called from | `BeamOutChar` (tail) |
| Calls | `BeamOutNext` (tail) |
| Reads | `$8190`-`$819D` (`GrazeOffsets`); `$8EC7`-`$8ECC` (`BeamReflected+5`, `BeamDirection`, `BeamNextDirection`); `$E04B` (`work space $E04B+`); `$E06A` (`work space $E06A+`); `$E10A` (`work space $E10A+`); `$E182`-`$E18C` (`work space $E182+`); 5 more ranges |
| Writes | `$8EC7` (`BeamReflected+5`) |

### `BeamReflectOut` (`$960D`)

**The outgoing beam meets a reflecting wall or a yellow polariser across it**

Along an axis as `BeamReflectIn` `$938F`: grazed, or straight back (OVERLOAD `$8FC5`, the trace ends). On a slope or a diagonal (`$965A`) the row of the new direction in `$8080` (eight bytes: two words, the two characters to test, then four directions by which of them are walls, +1 the first, +2 the second) gives the bounced direction. Its reverse: OVERLOAD. Else the beam is turned in place: the direction `$8ECB` = `$FF` (no incoming pass), the bounce count `$8EC0` + 1, and the vertex is drawn again (`BeamVertex` `$906E`) with the new direction. At 40 bounces OVERLOAD, at 150 the trace ends; the bounce count never passed 39 in the recordings (`$96B8` never ran).

Witness: L1 50666 (c1, c1g, cheat, hof, nameedit, L x9, rzx x31).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 32,912 calls (`stage1/rzx/r004833` 5,161, `stage1/rzx/r063909` 4,629, `stage1/rzx/r268227` 2,918 and 19 more) |
| Called from | `BeamOutChar` (tail), `BeamOutNext` (tail) |
| Calls | `BeamBackToLaser` (tail), `BeamVertex` (tail), `BeamOutNext` (tail) |
| Reads | `$8088`-`$80FE` (`OutBounceTable+8`); `$8190`-`$819F` (`GrazeOffsets`); `$8914`-`$8915` (`CharMapPointer`); `$8EC0`-`$8ECC` (`BeamSteps+1`, `BeamAtCentre`, `BeamReflected`, `BeamDirection` and 1 more); `$D700`-`$D707` (`CellGraphics`); `$E024`-`$E25C` (`work space $E024+`) |
| Writes | `$8EC0`-`$8ECC` (`BeamSteps+1`, `BeamAtCentre`, `BeamReflected`, `BeamDirection` and 1 more); `$EE16`-`$EEF6` (`work space $EE16+`); `$F403`-`$F4E3` (`work space $F403+`); `$F812`-`$F852` (`work space $F812+`); `$F872` (`work space $F872+`); `$F892` (`work space $F892+`); 11 more ranges |

### `MoveCursor` (`$9910`)

**Keep the control bits; with fire turn the mirror under the cursor, else move the cursor a cell**

The control bits A (from `ReadControls` `$9869`) go to ControlBits `$96C5`. Fire held: `TurnMirror` `$995E`. Else the four direction bits index CursorSteps `$993E` (dx, dy, diagonals included, opposite pairs cancel) and the cursor moves one cell, each axis only when it stays on the grid (column 0-14, row 0-8). No delay: the cursor moves a cell every pass of the main loop (4.85 frames a pass in the RZX run).

Witness: L1 117259 (c1, c1g, cheat, controls, corner, energy, energy-out, hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x59).

| | |
| --- | --- |
| Runs (c1g: the c1 recording's game window, from the jump to `$8382` (frame 15752 T 33930): the menu and play) | 1,044 calls, 66,279 t-states own (0.02 %) |
| Runs (the other recordings) | 1,044 calls (`stage1/c1` 1,044) |
| Called from | `ReadControls` (tail) |
| Reads | `$96C3`-`$96C5` (`CursorVars`, `CursorY`, `ControlBits`); `$9940`-`$994F` (`CursorSteps+2`); `$FD4B` (`work space $FD4B+`) |
| Writes | `$96C3`-`$96C6` (`CursorVars`, `CursorY`, `ControlBits`, `CursorMode`) |

### `TurnMirror` (`$995E`)

**Fire held: turn the mirror under the cursor one sixteenth to the right or to the left**

CursorMode `$96C6` = 7 (the square cursor). The cell under the cursor (`$FD23` + 17 x row + column) must be a mirror, `$01`-`$10` with or without bit 7 (bit 7: a mirror that also turns by itself, one step each pass of the grid drawing `$8960`, at `$89B1`); right (bit 1) adds one, left (bit 0) subtracts one, round from 16 to 1 and back; both or neither: nothing. Bit 7 is kept. Up and down do nothing while fire is held. One step a pass: a full turn takes 16 passes.

The angle: the trace (`$8FFB`) reflects the beam off mirror m to (m - 1 - direction + 8) AND 15, so mirror m lies at (m + 7) x 11.25 degrees: 1 upright, 9 level, a sixteenth of a turn of the beam per two steps of the mirror.

Runs: 48 813 (c1g, controls, kempston, menu, 58 RZX segments); turned right `$9988` 7649, left `$998F` 4205 (RZX).

Witness: L1 50258 (c1, c1g, controls, kempston, menu, L x20, rzx x58).

[Animation: `TurnMirror` at work](img/routines/TurnMirror.gif)

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `MarkCursorCells` (`$999F`)

**Mark the four characters under the cursor for redrawing**

Called each pass by the main loop (`$854D`) before the grid is drawn (`$8960`): the draw marks `$E300` of the cursor cell's 2 x 2 characters (column 2x + 1, row 2y + 1 of the 32 x 20 map) are set to 2, so the cell's own graphics replace last pass's cursor.

Witness: L1 117260 (c1, c1g, cheat, controls, corner, energy, energy-out, hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x59).

| | |
| --- | --- |
| Runs (c1g: the c1 recording's game window, from the jump to `$8382` (frame 15752 T 33930): the menu and play) | 1,044 calls, 222,372 t-states own (0.07 %) |
| Runs (the other recordings) | 115,346 calls (`stage2/rec/energy-out` 6,304, `stage1/energy` 6,269, `docs/integrate/rec/nameedit` 5,155 and 87 more) |
| Called from | `MainLoop` |
| Reads | `$96C3`-`$96C4` (`CursorVars`, `CursorY`) |
| Writes | `$E321`-`$E55E` (`work space $E321+`) |

### `DrawCursor` (`$99C6`)

**Show the cursor: the cell's colours inverted, or a white square while fire is held**

Called each pass by the main loop (`$85A1`) after the beam. HL = the colour buffer `$E600` at the cursor cell's up-left character. CursorMode `$96C6` = 0: `InvertColour` `$99F7` swaps ink and paper of the four characters (flash and bright kept). 7: the four colours are set to 7 (white on black) and the 16 x 16 square `CursorGraphic` `$9A37` is ORed into the pixel buffer `$E900` over the cell.

Witness: L1 117171 (c1, c1g, cheat, controls, corner, energy, energy-out, hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x59).

| | |
| --- | --- |
| Runs (c1g: the c1 recording's game window, from the jump to `$8382` (frame 15752 T 33930): the menu and play) | 1,043 calls, 259,430 t-states own (0.08 %) |
| Runs (the other recordings) | 115,259 calls (`stage2/rec/energy-out` 6,304, `stage1/energy` 6,268, `docs/integrate/rec/nameedit` 5,155 and 87 more) |
| Called from | `MainLoop` |
| Calls | `InvertColour` (falls into), `DrawCursorSquare` (tail) |
| Reads | `$96C3`-`$96C6` (`CursorVars`, `CursorY`, `ControlBits`, `CursorMode`) |

### `InvertColour` (`$99F7`)

**Swap the ink and paper of the colour byte at HL**

Keeps bits 7-6 (flash, bright). Falls in from `DrawCursor` for the fourth character.

Witness: L1 259824 (c1, c1g, cheat, controls, corner, energy, energy-out, hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x59).

| | |
| --- | --- |
| Runs (c1g: the c1 recording's game window, from the jump to `$8382` (frame 15752 T 33930): the menu and play) | 4,068 calls, 460,121 t-states own (0.14 %) |
| Runs (the other recordings) | 252,280 calls (`stage2/rec/energy-out` 25,216, `stage1/energy` 25,072, `docs/integrate/rec/nameedit` 20,620 and 87 more) |
| Called from | `DrawCursor` (falls into) |
| Reads | `$E621`-`$E85E` (`work space $E621+`) |
| Writes | `$E621`-`$E85E` (`work space $E621+`) |

### `DrawCursorSquare` (`$9A11`)

**Fire held: colour 7 and the square drawn round the cell**

Entered from `DrawCursor` `$99C6` with A = 7, HL at the colour buffer, B = the character row 2y + 1, C = the column 2x + 1.

Witness: L1 52215 (c1, c1g, controls, kempston, menu, L x20, rzx x58).

| | |
| --- | --- |
| Runs (c1g: the c1 recording's game window, from the jump to `$8382` (frame 15752 T 33930): the menu and play) | 26 calls, 41,586 t-states own (0.01 %) |
| Runs (the other recordings) | 52,189 calls (`stage1/rzx/r183540` 1,943, `stage1/rzx/r215327` 1,893, `stage1/rzx/r154293` 1,768 and 79 more) |
| Called from | `DrawCursor` (tail) |
| Reads | `$9A37`-`$9A56` (`CursorGraphic`); `$EA01`-`$FBFE` (`work space $EA01+`) |
| Writes | `$E621`-`$E85E` (`work space $E621+`); `$EA01`-`$FBFE` (`work space $EA01+`) |

## mainloop

`src/game/mainloop.asm`

### `SetUpLevel` (`$843C`)

**Set up the level in Level `$81FF` and play it: digits, flags, settings, score, build, wipe, counts, laser**

From LevelPanel (falls in), the demo's next level (`$856B`) and LoseLife (`$86D1`, the level again after a life lost).

1. The LEVEL digits: A = Level + 1 split into tens (B) and units; for the practice slots (Level >= 60) B = 10, the glyph P, and the units Level - 59 (P1-P3). Each digit is eight lines of LevelDigits `$88B0` + 8 x digit, drawn on lines 4-7 of character row 20 and lines 0-3 of row 21 (`$5486` / `$50A6` for the tens, the next column for the units): LEVEL 01 in the panel.

2. Clears the cursor's cell `$96C3` / `$96C4`, LevelDone, LifeLost, BeamOnMine, BeamInLaser, the energy-critical flag `$837E`, SoundFlags `$A8A6` and the gremlin-sound flag `$837C`.

3. The eight gremlin records at `$AB63` (6 bytes each): byte 0 = `$41`, `$4B`, `$55` ... (`$41` + 10 k), byte 1 = 0.

4. LevelSettings: byte 0 to `$A63C` (the energy rate operand), byte 1 to `$AB95` (the gremlin count). In practice the saved score is cleared (`$9B30`).

5. The seven explosion slots `$81B8-$81D3` cleared; the score `$9B3E` (five digits) = the score saved at the level's start `$9B44`, so a level begun again after a life lost starts from the score it began with; the score's field on the screen (lines 3-7 of row 21, columns 26-31) cleared, its left edge pixel kept.

6. BuildLevel `$891A` (the grid, the character map, the buffers); `$9B0A` prints the score, `$9B53` the high score; WipeInPlayArea `$8CA2` brings the play area onto the screen; `$A52F` resets the overload and energy bars, sets the charging flag `$A509` and the message CHARGING LASER (DEMO in the demo).

7. Counts the level's bytes: D = the cells (`$40`), E = the mirrors (`$01-$10`; turning mirrors, bit 7 set, are not counted). MirrorCount `$837A` = E (the charging's scramble `$A598` turns fewer mirrors when there are 30 or more); CellsLeft `$8380` = D; the points of a burnt cell (the operand of `LD B,n` at CellPoints `$8F62`) = 12 (120 points), or 3 (30 points) when the level has 30 or more cells (levels 4, 9, 14 ... 59: 110-120 cells; 38, 58, 60).

8. FindLaser `$8AC1`, then MainLoop.

Run at every level start of every play recording (165 in all).

Witness: L1 200 (c1, c1g, cheat, controls, energy, energy-out, hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x59).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 86 calls (`stage1/menu` 61, `docs/integrate/rec/nameedit` 3, `stage2/rec/hof` 3 and 8 more) |
| Called from | `LevelPanel` (falls into), `MainLoop` (tail), `LoseLifeDrained` (tail) |
| Calls | `BuildLevel`, `FindLaser`, `WipeInPlayArea`, `PrintScore`, `ClearSavedScore`, `PrintHighScore`, `ResetBars` |
| Reads | `$81FF` (`Level`); `$8385`-`$8407` (`LevelSettings`, `PracticeFlag`); `$88B0`-`$88FF` (`LevelDigits`); `$8912`-`$8913` (`LevelAddress`); `$9B44`-`$9B48` (`SavedScore`); `$B000`-`$CFA3` (`LevelData`) |
| Writes | `$50A6`-`$50A7` (screen); `$51A6`-`$51A7` (screen); `$52A6`-`$52A7` (screen); `$53A6`-`$53A7` (screen); `$53BA`-`$53BF` (screen); `$5486`-`$5487` (screen); 16 more ranges |

### `MainLoop` (`$854A`)

**One pass of play: keys, cursor, grid, beam, gremlins, the screen; then PassEnd**

1. `$97F0` (the keys and the controls), `$999F`, RenderGrid `$8960` (the grid into the character map, the marked characters into the buffers).

2. While the laser charges (`$A509` nonzero) no beam is traced. In the demo (`$8379` set) the pass instead waits a Delay and goes on to the next level (`$855F`): every level in turn, shown for one pass while it charges, then TitleLoop after the 60th (`$856E`); the `menu` recording runs `$855F` 60 times and `$856E` once.

3. Else, unless FindLaser found no laser (`$8378` = `$FF`), the beam's start: direction `$8ECB` = `$8378`, x `$8ECD` = `$8376`, y `$8ECE` = `$8377` (the half-cell in front of the laser); the beam's graphics bank `$8381` = `$40` in every other 8-frame spell of FrameCounter while the energy is critical (`$837E`), else 0: the beam flickers; TraceBeam `$8ED6`.

4. `$9A57`, `$99C6`, the gremlins `$AB9F` (not while charging), CopyPlayArea `$8C10`; then PassEnd.

The pass takes 4.85 frames on average in the RZX run (WALKTHROUGH 1).

Witness: L1 117268 (c1, c1g, cheat, controls, corner, energy, energy-out, hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x59).

[Animation: `MainLoop` at work](img/routines/MainLoop.gif)

| | |
| --- | --- |
| Runs (c1g: the c1 recording's game window, from the jump to `$8382` (frame 15752 T 33930): the menu and play) | run into, not called, 974,146 t-states own (0.29 %) |
| Runs (the other recordings) | run into, not called (`stage2/rec/energy-out`, `stage1/energy`, `docs/integrate/rec/nameedit` and 14 more) |
| Calls | `TitleLoop` (tail), `SetUpLevel` (tail), `Delay`, `RenderGrid`, `CopyPlayArea`, `TraceBeam`, `ReadKeys`, `MarkCursorCells`, `DrawCursor`, `CursorFire`, `UpdateGremlins` |
| Reads | `$81B8`-`$81D0` (`ExplosionSlots`); `$81FF` (`Level`); `$8376`-`$8380` (`BeamStartX`, `BeamStartY`, `BeamStartDirection`, `DemoFlag` and 7 more); `$8ED2`-`$8ED3` (`LevelDone`, `LifeLost`); `$A509` (`LaserCharging`); `$A8A6` (`SoundFlags`) |
| Writes | `$81FF` (`Level`); `$837B`-`$8381` (`BurnSoundFlag`, `GremlinSoundFlag`, `Lives`, `EnergyCritical` and 3 more); `$8ECB`-`$8ECE` (`BeamDirection`, `BeamNextDirection`, `BeamX`, `BeamY`); `$A8A6` (`SoundFlags`) |

### `PassEnd` (`$85AE`)

**The pass's second half: sounds, overload, life lost, energy, contact, the last cell, the explosions**

Falls in from MainLoop.

1. The gremlin sound: when `$837C` is set (at `$9ADE`, where the gremlin record on the cursor's cell is reset), PlaySound `$A8C0` with `$81ED`; `$837C` and the burn-sound flag `$837B` cleared.

2. `$A683` (the overload: the beam on a mine or back in the laser fills the OVERLOAD bar); LifeLost set: LoseLife `$866A`. `$A613` (the charging, then the energy drain); LevelDone set (the beam reached the receiver): LevelComplete `$87D4`.

3. SoundFlags bit 3 off. CellsLeft `$8380` = 0 (the last cell burnt): OpenReceiver `$8B3F` (the element in front of the receiver starts to explode), PlaySound ReceiverOpenSound, 25 points (250).

4. The explosions: each of the seven 4-byte slots at `$81B8` (the grid address, high byte first, then y and x in half-cells; high byte 0 = free) is a cell burning. The cell's code: a code below `$58` (the cell just hit) becomes `$57` and sets `$837B`; then one step a pass, `$58` to `$5C` (SoundFlags bit 3 while `$58`-`$59`), and at `$5D` the cell is emptied (code 0), the slot freed and CellsLeft decremented. Each step marks the cell's four characters (DrawMarks `$E300`) with 2, to be drawn twice.

5. A new explosion this pass (`$837B` set): PlaySound `$81D4`. Back to MainLoop.

An entry of its own: the `gameover` recording starts from a snapshot taken inside CopyPlayArea (called at `$85AB`), so its L1 marks a routine root at the return address.

Witness: L1 117162 (c1, c1g, cheat, controls, corner, energy, energy-out, gameover, hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x59).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings run into, not called (`stage1/gameover`) |
| Calls | `LoseLife` (tail), `LevelComplete` (tail), `OpenReceiver`, `AddScore`, `DrainEnergy`, `UpdateOverload`, `PlaySound` |
| Reads | `$837C` (`GremlinSoundFlag`); `$8ED3` (`LifeLost`) |
| Writes | `$837B`-`$837C` (`BurnSoundFlag`, `GremlinSoundFlag`) |

### `LevelComplete` (`$87D4`)

**The beam reached the receiver: CONTACT!, the next level number, then the bonus**

From PassEnd (`$85D0`) when LevelDone `$8ED2` is set (BeamStep at `$8FA9`). SoundFlags = 0; MessageNumber `$A104` = `$18`, MessageText = `$A16C` (CONTACT!); PlaySound `$81F7`; Level + 1; a Delay, then LevelCompletePause.

Run 18 times, the 18 levels our RZX replay completes (WALKTHROUGH 6.1).

Witness: L1 38 (L x20, rzx x18).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 38 calls (`stage1/rzx/r263143` 1, `stage2/rec/L45` 1, `stage2/rec/L55` 1 and 35 more) |
| Called from | `PassEnd` (tail) |
| Calls | `Delay`, `PlaySound` |
| Reads | `$54F1`-`$54F8` (screen); `$5800`-`$5A7E` (screen); `$81FF` (`Level`); `$837D` (`Lives`); `$9B3E`-`$9B42` (`ScoreDigits`); `$A507`-`$A508` (`EnergyBarPointer`) |
| Writes | `$54AA`-`$54AF` (screen); `$54F1`-`$54F8` (screen); `$55AA`-`$55AF` (screen); `$55F1`-`$55F8` (screen); `$56AA`-`$56AF` (screen); `$56F1`-`$56F8` (screen); 7 more ranges |

### `LevelCompletePause` (`$87F3`)

**Two more Delays, the play area magenta, the energy and lives bonus, then the next level**

1. Two Delays (with LevelComplete's, about 36 frames); the play area's 640 attributes = `$03` (magenta ink on black).

2. The energy bonus: while the energy bar (`$A507`, the byte the drain has reached) has pixels: 10 points (`$9AF3`, B = 1), a short tone (`$A843`, HL = `$0A3C`), and one pixel shifted out of the bar's byte on its three lines (`SLA`, as the drain does at `$A646`); an empty byte moves the pointer one byte left, down to `$54F1`, the bar's first.

3. The lives bonus: for each life left, from the last: two Delays, its bar hollowed (as LoseLifeDrained does), 500 points (`$9AF3`, B = `$32`), PlaySound `$81ED`, then `$A843` with the HL PlaySound leaves.

4. Four Delays; the score is saved as the next level's start score (`$9B3E` to `$9B44`); Lives = 3: every level starts with three lives (LevelPanel redraws the three bars).

5. Level 60 (after the 60th level): TheEnd. Level 63 (after the third practice level): TitleLoop. Else LevelPanel, the next level.

An entry of its own: 42 of the RZX segments start from a snapshot taken at the level change (`$81FF` written at `$87ED`), inside the Delay called at `$87F0`, so their L1s mark a routine root at the return address. Run 78 times (all 60 RZX segments: the 42 roots and the 18 completions).

Witness: L1 116 (ending, hof, nameedit, L x20, rzx x60).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings run into, not called (`stage2/rec/ending`, `stage1/rzx/r344752`, `stage1/rzx/r166812` and 42 more) |
| Calls | `TitleLoop` (tail), `LevelPanel` (tail), `Delay`, `AddScore`, `TwoTone`, `PlaySound`, `EndingScreen`, `TitleTune` |
| Reads | `$54F1`-`$54F7` (screen); `$5800`-`$5A7E` (screen); `$81FF` (`Level`); `$837D` (`Lives`); `$9B3E`-`$9B42` (`ScoreDigits`); `$A507`-`$A508` (`EnergyBarPointer`); 1 more ranges |
| Writes | `$54AA`-`$54AF` (screen); `$54F1`-`$54F7` (screen); `$55AA`-`$55AF` (screen); `$55F1`-`$55F7` (screen); `$56AA`-`$56AF` (screen); `$56F1`-`$56F7` (screen); 5 more ranges |
| Ports in | `$00FE` |

### `Delay` (`$8908`)

**Wait 255 x 255 DJNZ loops (about 12 frames, interrupts as they are)**

C = 255 outer passes of B = 255 `DJNZ`: about 845 000 T-states, 12 frames of 69 888 T. Leaves A and HL alone, BC = 0.

Callers: NewGame (twice), the demo (`$855F`), LoseLife (`$86CA`), LevelComplete and LevelCompletePause (seven times a level and two for each life left), `$9DE1`, the title `$A729-$A732` (four), the ending `$A8D9`, `$A943`, `$A963-$A96C`.

Witness: L1 1400 (c1, c1g, controls, ending, energy, energy-out, gameover, hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x60).

| | |
| --- | --- |
| Runs (c1g: the c1 recording's game window, from the jump to `$8382` (frame 15752 T 33930): the menu and play) | 6 calls, 5,099,562 t-states own (1.52 %) |
| Runs (the other recordings) | 1,394 calls (`stage1/menu` 72, `stage1/rzx/r344752` 49, `stage2/rec/ending` 44 and 90 more) |
| Called from | `NewGame`, `NewGameDelay2`, `MainLoop`, `LoseLifeDrained`, `LevelComplete`, `LevelCompletePause`, `HallOfFame`, `TitleScreen`, `EndingScreen` |
| Calls | `DelayOuter` (falls into) |

### `DelayOuter` (`$890A`)

**DelayOuter**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 99,061 calls (`stage2/rec/ending` 11,257, `docs/integrate/rec/nameedit` 6,604, `stage2/rec/hof` 6,604 and 20 more) |
| Called from | `Delay` (falls into), `DelayInner` (tail) |
| Calls | `DelayInner` (falls into) |

### `DelayInner` (`$890C`)

**DelayInner**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 99,061 calls (`stage2/rec/ending` 11,257, `docs/integrate/rec/nameedit` 6,604, `stage2/rec/hof` 6,604 and 20 more) |
| Called from | `DelayOuter` (falls into) |
| Calls | `DelayOuter` (tail) |

## sound

`src/game/sound.asm`

### `PlayTone` (`$A83F`)

**Kind 0: L, H from the record, then TwoTone**

From PlaySound. The record `$81E8` (SoundFlags bit 4, the charge) is the only kind-0 record found: L = `$8C`, H = 2.

Evidence: 16 418 runs.

Witness: L1 22256 (c1, c1g, cheat, controls, energy, energy-out, hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x59).

| | |
| --- | --- |
| Runs (c1g: the c1 recording's game window, from the jump to `$8382` (frame 15752 T 33930): the menu and play) | 152 calls, 3,648 t-states own (0.00 %) |
| Runs (the other recordings) | 21,657 calls (`stage1/rzx/r307588` 558, `stage1/rzx/r319697` 544, `stage1/rzx/r024486` 510 and 87 more) |
| Called from | `PlaySound` (tail) |
| Calls | `TwoTone` (falls into) |
| Reads | `$81E9`-`$81EA` (`ChargeWarble+1`) |

### `TwoTone` (`$A843`)

**A warble: two square waves of periods 256-L and 257-L loops toggle the speaker, for H x 256 loops**

D counts up from L, E from L-1; each that wraps to 0 toggles the speaker and MIC bits (`XOR $18`) and starts again from L (E from L-1). The two nearly equal periods beat against each other. B x C = H x 256 loops.

Also called directly with HL as the tone: the menu (`$465A` 14.4 frames, `$28A0` 8.2, `$1478` 4.1), the pause (`$0F3C` 3.1), the abort (`$C814` 41.1), the name entry (`$3250` 10.3), the level complete (`$0A3C` 2.1 each step of the bonus count, and `$0204` (0.41 frame) after each life of the bonus, at `$8853`: HL is what PlaySweep left, GremlinSound's step and half-cycles); T-states by SkoolKit's simulator (work/ann/03-irq/simtime.py, no contention).

Evidence: 17 972 runs.

Witness: L1 24908 (c1, c1g, cheat, controls, ending, energy, energy-out, gameover, hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x60).

| | |
| --- | --- |
| Runs (c1g: the c1 recording's game window, from the jump to `$8382` (frame 15752 T 33930): the menu and play) | 158 calls, 7,114,051 t-states own (2.12 %) |
| Runs (the other recordings) | 24,303 calls (`stage1/rzx/r307588` 568, `stage1/rzx/r319697` 559, `stage2/rec/hof` 536 and 90 more) |
| Called from | `LoseLifeDrained`, `LevelCompletePause`, `PauseGame`, `ReadKeys`, `HallOfFame`, `OptionsMenu`, `PlayTone` (falls into) |
| Ports out | `$00FE`, `$18FE` |

### `PlaySweep` (`$A85E`)

**Kind 1: E steps of L half-cycles, each of a delay D, D - H after each step (a falling or rising sweep)**

Record: H (the step), L (half-cycles a step), D (the first delay, `DJNZ` loops), E (steps). H > 0 shortens the delay (the pitch rises), `$FE` (-2, the mine's `$81D9`) lengthens it.

Records: `$81D4` (BurnSound: played directly by PassEnd `$865A` on a pass with a new explosion; its flag bit 0 is never set), `$81D9` (bit 1, the beam on a mine, 0.20 frame), `$81DE` (bit 2, the beam in the laser, 0.02), `$81ED` (`$85B5`, 2.2 frames), `$81F2` (the charge done, the ending, 17.9), `$81F7` (CONTACT!, 43.3), `$8660` (5.99), `$8665` (a life lost, 2.6).

Evidence: 43 809 runs.

Witness: L1 50108 (c1, c1g, cheat, controls, corner, ending, energy, energy-out, gameover, hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x60).

[Animation: `PlaySweep` at work, port](img/routines/PlaySweep-port.gif)

| | |
| --- | --- |
| Runs (c1g: the c1 recording's game window, from the jump to `$8382` (frame 15752 T 33930): the menu and play) | 1 call, 1,253,676 t-states own (0.37 %) |
| Runs (the other recordings) | 50,102 calls (`stage1/rzx/r295329` 2,153, `stage1/rzx/r268227` 2,109, `stage1/rzx/r204297` 1,880 and 90 more) |
| Called from | `PlaySound` (tail) |
| Reads | `$81D5`-`$81FB` (`BurnSound+1`, `MineSound`, `LaserBackSound`, `BurningNoise` and 4 more); `$8661`-`$8669` (`ReceiverOpenSound+1`, `LifeLostSound`); `$8696`-`$8699` (`EnergyDrainedSound+1`) |
| Ports out | `$00FE`, `$18FE` |

### `PlayNoise` (`$A87A`)

**Kind 2: E bursts of random length and period; the record's 4th byte is an opcode written into the code**

Record: D (the period mask), E (bursts), C (the length mask), and an opcode byte stored at NoiseOp `$A89F` (self-modifying: `$A2` = `AND D`, the image's own). Each burst: L half-cycles of a delay B, then a random pair from `$8E15`: L = (L AND C) + 1, B = (H op D) + 1.

The record `$81E3` (SoundFlags bit 3: a burning cell, `$860F`): D = 2, E = 4, C = `$0A`, `AND D`; 0.04 frame.

Evidence: 11 171 runs (53 RZX segments).

Witness: L1 16546 (corner, L x20, rzx x53).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 16,529 calls (`stage2/rec/L39` 1,018, `stage1/rzx/r183540` 814, `stage1/rzx/r300124` 794 and 70 more) |
| Called from | `PlaySound` (tail) |
| Calls | `Random` |
| Reads | `$81E4`-`$81E7` (`BurningNoise+1`) |
| Writes | `$A89F` (`NoiseOp`) |
| Ports out | `$00FE`, `$18FE` |

### `PlaySoundFlags` (`$A8A7`)

**From the interrupt: the effect of the lowest set bit 0-4 of SoundFlags, record `$81D4` + 5 x bit**

B counts 5 down while the flags are rotated right; the first carry gives the bit (5 - B), HL = `$81D4` + 5 x bit, then PlaySound. No bit: return.

Evidence: 381 862 runs (every interrupt).

Witness: L1 487506 (c1, c1g, cheat, controls, corner, ending, energy, energy-out, gameover, hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x60).

| | |
| --- | --- |
| Runs (c1g: the c1 recording's game window, from the jump to `$8382` (frame 15752 T 33930): the menu and play) | 4,473 calls, 655,577 t-states own (0.20 %) |
| Runs (the other recordings) | 479,633 calls (`stage2/rec/energy-out` 18,370, `stage1/energy` 18,113, `docs/integrate/rec/nameedit` 17,189 and 90 more) |
| Called from | `InterruptExit` |
| Calls | `PlaySound` (falls into) |
| Reads | `$A8A6` (`SoundFlags`) |

### `PlaySound` (`$A8C0`)

**Play the 5-byte effect record at HL: kind 0 PlayTone, 1 PlaySweep, else PlayNoise**

Called directly by the main code (`$85B5`, `$85E7`, `$865A`, `$8683`, `$869D`, `$86C4`, `$87E6`, `$8850`, `$8899`, `$889F`, ChargeLaser `$A60F`, EndingScreen `$A94C`) and from PlaySoundFlags.

Evidence: 71 398 runs.

Witness: L1 88910 (c1, c1g, cheat, controls, corner, ending, energy, energy-out, gameover, hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x60).

| | |
| --- | --- |
| Runs (c1g: the c1 recording's game window, from the jump to `$8382` (frame 15752 T 33930): the menu and play) | 153 calls, 4,148 t-states own (0.00 %) |
| Runs (the other recordings) | 88,288 calls (`stage1/rzx/r268227` 2,658, `stage1/rzx/r183540` 2,406, `stage1/rzx/r327592` 2,350 and 90 more) |
| Called from | `PassEnd`, `LoseLife`, `LoseLifeDrained`, `LevelComplete`, `LevelCompletePause`, `ChargeLaser`, `PlaySoundFlags` (falls into), `EndingScreen` |
| Calls | `PlayTone` (tail), `PlaySweep` (tail), `PlayNoise` (tail) |
| Reads | `$81D4`-`$81F7` (`BurnSound`, `MineSound`, `LaserBackSound`, `BurningNoise` and 4 more); `$8660`-`$8665` (`ReceiverOpenSound`, `LifeLostSound`); `$8695` (`EnergyDrainedSound`) |

### `TitleTune` (`$AD79`)

**The title tune with the interrupt off: 176 notes from TitleTuneData, again and again until a key**

`DI`; IX = TitleTuneData, B = `$B0` notes; each note: H, L, D the three voices' periods, BC = `$1770` (6000) loops of PlayNote. After each note the keyboard (all half rows): a key ends it with `EI`. After the last note it starts again.

Called by TitleScreen `$A754`, the pause `$97AE` (the "pause's tune"), the ending `$88AA`. One note takes 677 051-733 334 T (9.7-10.5 frames), the tune 35.4 s (SkoolKit's simulator, work/ann/03-irq/simtime.py).

Evidence: 12 runs (`c1g`, `controls`, `gameover`, `kempston`, `menu`, `mine`, `overload`, `rzx-344752`).

Witness: L1 17 (c1, c1g, controls, ending, energy-out, gameover, hof, kempston, menu, mine, nameedit, overload, rzx344752).

| | |
| --- | --- |
| Runs (c1g: the c1 recording's game window, from the jump to `$8382` (frame 15752 T 33930): the menu and play) | 1 call, 3,515 t-states own (0.00 %) |
| Runs (the other recordings) | 16 calls (`stage1/controls` 4, `stage1/menu` 2, `stage1/gameover` 1 and 9 more) |
| Called from | `LevelCompletePause`, `PauseGame`, `TitleScreen` |
| Reads | `$ADF0`-`$AFFF` (`TitleTuneData`) |
| Ports in | `$00FE` |

### `TitleTuneNoteLoop` (`$AD80`)

**TitleTuneNoteLoop**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings run into, not called (`docs/dfA/rec/practice`, `stage1/energy`) |
| Calls | `PlayNote` |
| Reads | `$AF52`-`$AFAB` (`TitleTuneData+354`) |
| Ports in | `$00FE` |

### `PlayNote` (`$ADA7`)

**The inner loop of a note: three counters; each that reaches 0 sends a short pulse and reloads**

H, L, D count down once a loop; at 0 the speaker goes off (`OUT` 0) for C = 15 `DJNZ` loops and back on (`$10`) for 16 - C = 1, then the counter is reloaded from the note (IX+0, +1, +2). So each voice is a train of short pulses at 3.5 MHz / (about 108 T x period): `$42` about 490 Hz, `$84` about 245 Hz. BC on the stack counts the note's loops (`ADE8`); `NOP NOP` pad the loop.

Evidence: 6 919 984 runs.

Witness: L1 10535890 (c1, c1g, controls, ending, energy, energy-out, gameover, hof, kempston, menu, mine, nameedit, overload, practice, rzx344752).

| | |
| --- | --- |
| Runs (c1g: the c1 recording's game window, from the jump to `$8382` (frame 15752 T 33930): the menu and play) | 19 calls, 13,473,433 t-states own (4.01 %) |
| Runs (the other recordings) | 5,592,729 calls (`stage1/menu` 2,185,086, `stage2/rec/energy-out` 1,477,736, `stage1/controls` 1,152,802 and 11 more) |
| Called from | `TitleTuneNoteLoop`, `NoteLoopEnd` (tail) |
| Calls | `NoteLoopEnd` (falls into) |
| Reads | `$ADF0`-`$AFFF` (`TitleTuneData`) |
| Ports out | `$00FE`, `$10FE` |

### `NoteLoopEnd` (`$ADE8`)

**NoteLoopEnd**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 5,591,918 calls (`stage1/menu` 2,185,085, `stage2/rec/energy-out` 1,477,736, `stage1/controls` 1,152,801 and 3 more) |
| Called from | `PlayNote` (falls into) |
| Calls | `PlayNote` (tail) |

## controls

`src/game/controls.asm`

### `PauseGame` (`$973A`)

**P: INTERMISSION until ENTER, then the game goes on as it was**

Jumped to by `ReadKeys` `$97F0` when P is held without ENTER. Not in the demo (`$8379` set). With interrupts off: a short tone (`$A843`, HL = `$0F3C`), the COMPUTER line's state, the energy tick and the sound flags saved in `CursorVars` (`$96C7`), the sound flags and `$A10D` cleared; five pixel rows of the screen at `$50E0` saved and " INTERMISSION  " printed there in the panel's font (rows 2-6 of each glyph), with a bar `$80` in its first column; wait for every key to be let go, then the pause tune `$AD79`, the COMPUTER line set to "PRESS ENTER FOR MORE ACTION" (`$A2C3`), interrupts on, wait for ENTER; then the tone again and everything put back.

The energy tick is restored from its copy, so the pause costs no energy. Recording: `controls` (P at the frame the input script gives, the pause's tune, ENTER), one run.

Witness: L1 1 (controls).

| | |
| --- | --- |
| Runs | ran within another entry's routine (reached by a jump or by running on, its calls below), no runs of its own counted |
| Calls | `TwoTone`, `TitleTune` |

### `ReadKeys` (`$97F0`)

**Each pass: P pauses, U and G together abort the game, then the controls**

Called first in each pass of the main loop (`$854A`; 90 922 runs over all recordings). Clears CursorMode `$96C6`. P (`$DFFE` bit 0) without ENTER: PauseGame `$973A`. U (`$DFFE` bit 3) with G (`$FDFE` bit 4): the COMPUTER line shows message `$14`, "GAME ABORTED" (`$A17B`, "DEMO ABORTED" `$A18A` in the demo), a tone (`$A843`, HL = `$C814`), the return address is dropped and the game goes back to the title (`$840C`). Then `ReadControls` `$9869`.

A quirk: with P and ENTER both held the abort test reads bit 3 of the ENTER half-row (J) for U.

Recordings: `controls` aborts with U + G ("GAME ABORTED", screen 2000), `menu` the demo (SPACE ends it elsewhere) and practice (U + G); `$9811` 5 runs (controls, kempston, menu).

Witness: L1 117268 (c1, c1g, cheat, controls, corner, energy, energy-out, hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x59).

| | |
| --- | --- |
| Runs (c1g: the c1 recording's game window, from the jump to `$8382` (frame 15752 T 33930): the menu and play) | 1,044 calls, 351,798 t-states own (0.10 %) |
| Runs (the other recordings) | 115,351 calls (`stage2/rec/energy-out` 6,304, `stage1/energy` 6,269, `docs/integrate/rec/nameedit` 5,155 and 87 more) |
| Called from | `MainLoop` |
| Calls | `TitleLoop` (tail), `TwoTone` |
| Reads | `$50E0`-`$50EF` (screen); `$51E0`-`$51EF` (screen); `$52E0`-`$52EF` (screen); `$53E0`-`$53EF` (screen); `$54E0`-`$54EF` (screen); `$81FD` (`ControlMethod`); 12 more ranges |
| Writes | `$50E0`-`$50EF` (screen); `$51E0`-`$51EF` (screen); `$52E0`-`$52EF` (screen); `$53E0`-`$53EF` (screen); `$54E0`-`$54EF` (screen); `$96C3`-`$972A` (`CursorVars`, `CursorY`, `ControlBits`, `CursorMode` and 4 more); 4 more ranges |
| Ports in | `$00FE`, `$7EFE`, `$BFFE`, `$DFFE`, `$EFFE`, `$F7FE`, `$FBFE`, `$FDFE` |

### `LevelCheat` (`$9832`)

**The dormant level cheat: W for the next level, S for the one before**

Never reached in the game: the `JP $9869` at `$982F` jumps over it and no other jump or call leads here. Recorded working on a clone: `cheat` (work/stage2/cheat/cheat.szx = level 1 in play with the POKE `$982F-$9831` = 0, tests/inputs/cheat.txt): W twice took the level from 0 to 1 and 2 (`$9847-$984F` 2 runs), S back to 1 (`$985A-$9866` once); the Y + T drop `$983E` ran in no recording. A is the half-row `ReadKeys` read last: `$DFFE` (Y is its bit 4) unless U is held. W (`$FBFE` bit 1): the level `$81FF` + 1 (no upper limit); S (`$FDFE` bit 1): the level - 1, not below 0; either drops `ReadKeys`' return address and restarts at the level set-up `$843C` (the `$843C` loop never returns, so the stack's depth does not matter). Neither: on to `ReadControls`.

Y (bit 4 of A) and T (`$FBFE` bit 4) held together drop one more return address first. With W or S that is harmless (the restart); without them `ReadControls` would return past the main pass, so the Y + T test looks like a guard whose jump sense went wrong, or a leftover. A `JR $9832` (or no `JP`) at `$982F` would bring the cheat back.

Witness: L1 531 (cheat).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `ReadControls` (`$9869`)

**Read the chosen control method into the control bits: 0 left, 1 right, 2 down, 3 up, 4 fire**

By ControlMethod `$81FD`: 0 the keyboard (Q up, A down, K left, L right, fire any key of the bottom row: CAPS SHIFT to V and B to SPACE, port `$7EFE`), 1 Sinclair (`$98AD`: both Interface 2 ports, 1-5 left, right, down, up, fire and 6-0 left, right, down, up, fire, ORed), 2 Kempston (`ReadKempston` `$98D2`), 3 Protek / AGF cursor keys (`$98E7`: 5 left, 8 right, 6 down, 7 up, 0 fire). All four end in `MoveCursor` `$9910`.

Runs: the keyboard `$987B` 1361 (c1g, controls), Sinclair `$98AD` 88 978 (the default; every RZX segment), Kempston `$98D2` 301 (kempston), Protek `$98E7` 276 (controls).

Witness: L1 117259 (c1, c1g, cheat, controls, corner, energy, energy-out, hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x59).

| | |
| --- | --- |
| Runs | ran within another entry's routine (reached by a jump or by running on, its calls below), no runs of its own counted |
| Calls | `ReadKempston` (tail), `MoveCursor` (tail) |

### `ReadKempston` (`$98D2`)

**Kempston (port `$1F`): the control bits, left and right swapped into place**

Port `$1F` gives bit 0 right, 1 left, 2 down, 3 up, 4 fire; down, up and fire are kept, right becomes bit 1 and left bit 0. Then `MoveCursor`. The entry point `$98E7` reads the Protek / AGF keys (5 left, 6 down, 7 up, 8 right, 0 fire). Recording `kempston`: 301 runs, the cursor moved and a mirror turned.

Witness: L1 301 (kempston).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 301 calls (`stage1/kempston` 301) |
| Called from | `ReadControls` (tail) |
| Reads | `$96C3`-`$96C5` (`CursorVars`, `CursorY`, `ControlBits`); `$9942`-`$994F` (`CursorSteps+4`); `$FD2E` (`work space $FD2E+`) |
| Writes | `$96C3`-`$96C6` (`CursorVars`, `CursorY`, `ControlBits`, `CursorMode`) |
| Ports in | `$021F` |

## render

`src/game/render.asm`

### `RenderGrid` (`$8960`)

**Each grid cell to four character codes in the character map; turning elements step on; then DrawMarkedChars**

For the 9 x 15 cells of LevelGrid `$FD23`, CharMapPointer runs from `$E021` (row 1, column 1: the cell (r, c) is the characters (2r+1, 2c+1) to (2r+2, 2c+2)); the cell code's four bytes in CellTable `$8200` + 4 x code are the top-left, top-right, bottom-left and bottom-right character codes.

A code with bit 7 set is a turning element (RenderGridTurning): the code steps on once a pass, the mirrors `$01-$10` round 16 angles, the blocks `$11-$18` and `$19-$20` round their 8, and the cell's four DrawMarks are set to 1. Other codes with bit 7 (`$A1` up) draw as their low code without turning.

Writes the map every pass but marks only the turning cells: a cell another routine changes is drawn because that routine marks it.

Jumps to DrawMarkedChars. From MainLoop (`$8550`) every pass and from BuildLevel (falls in).

Witness: L1 117459 (c1, c1g, cheat, controls, corner, energy, energy-out, hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x59).

| | |
| --- | --- |
| Runs (c1g: the c1 recording's game window, from the jump to `$8382` (frame 15752 T 33930): the menu and play) | 1,045 calls, 111,191,135 t-states own (33.09 %) |
| Runs (the other recordings) | 115,541 calls (`stage2/rec/energy-out` 6,307, `stage1/energy` 6,272, `docs/integrate/rec/nameedit` 5,158 and 87 more) |
| Called from | `MainLoop`, `BuildLevel` (falls into) |
| Calls | `DrawMarkedChars` (tail) |
| Reads | `$8200`-`$830B` (`CellTable`); `$831C`-`$8373` (`CellTable+284`); `$8407` (`PracticeFlag`); `$8914`-`$8915` (`CharMapPointer`); `$D700`-`$DAFF` (`CellGraphics`); `$DB80`-`$DD9F` (`CellGraphics+1152`); 12 more ranges |
| Writes | `$8914`-`$8915` (`CharMapPointer`); `$E021`-`$E25E` (`work space $E021+`); `$E325`-`$E55E` (`work space $E325+`); `$E600`-`$E87F` (`work space $E600+`); `$E900`-`$FCFF` (`work space $E900+`); `$FD25`-`$FDB9` (`work space $FD25+`) |

### `DrawMarkedChars` (`$8A09`)

**Draw every marked character into the play buffers, the practice line, the frame round the play area**

For each of the 640 DrawMarks `$E300` with a nonzero mark: the character code at the same place in the character map (`$E000`), its colour `$DF00` + code (CellColours) to ColourBuffer `$E600`, its eight lines `$D700` + 8 x code (CellGraphics) to PixelBuffer `$E900` (row r, column c at `$E900` + 256 r + c, a line every 32 bytes). The marks are left as they are: CopyPlayArea counts them down.

In practice (PracticeFlag) PrintPlay `$8E47` writes PracticeText on row 19. Then the frame: line 0 and line 159 of the pixel buffer all set, and the left pixel of column 0 and the right pixel of column 31 on lines 1-158.

From RenderGrid. The practice line `$8A6E` ran 615 times in `practice` (`work/docs/dfA/rec/practice`).

Witness: L1 117449 (c1, c1g, cheat, controls, corner, energy, energy-out, hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x59).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 34,358 calls (`stage1/rzx/r319697` 2,426, `stage1/rzx/r107497` 2,221, `stage1/rzx/r146186` 2,050 and 27 more) |
| Called from | `RenderGrid` (tail) |
| Calls | `PrintPlay` |
| Reads | `$8407` (`PracticeFlag`); `$D700`-`$D887` (`CellGraphics`); `$D8C8`-`$D947` (`CellGraphics+456`); `$DA68`-`$DAFF` (`CellGraphics+872`); `$DB80`-`$DD9F` (`CellGraphics+1152`); `$DF00`-`$DF48` (`CellColours`); 11 more ranges |
| Writes | `$E600`-`$E87F` (`work space $E600+`); `$E900`-`$FCFF` (`work space $E900+`) |

### `CopyFullScreen` (`$8B9B`)

**Copy the full-screen buffer to the screen: pixels `$E500` (24 rows of 256) and attributes `$E200`**

The linear buffer (`$E500` + 256 r + 32 l + c, character row r, line l) to the screen in its own layout, 24 rows x 8 lines x 32 `LDI`; then 767 attributes from `$E200` to `$5800` (the last one, row 23 column 31, is not copied).

From the ending (`$A8D4`) and `$9DD6` (the menu). Run in `rzx-344752` (the ending, `$A8D4`) and in `hof` (`$9DD6`, after the name AGENT).

Witness: L1 5 (ending, hof, nameedit, rzx344752).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 5 calls (`stage1/rzx/r344752` 2, `stage2/rec/ending` 1, `docs/integrate/rec/nameedit` 1 and 1 more) |
| Called from | `HallOfFame`, `EndingScreen` |
| Reads | `$E200`-`$FCFF` (`work space $E200+`) |
| Writes | `$4000`-`$5AFE` (screen) |

### `CopyPlayArea` (`$8C10`)

**Copy the marked characters of the play area to the screen, counting each mark down; then all colours**

Walks DrawMarks backwards from `$E57F` (row 19, column 31) to `$E300`: a mark's low byte is the screen's low byte, its page (`$E3`-`$E5`) the screen third, so the character at the mark is the screen address B x 256 + E (B from `$57` down to `$47`, the third's last line). A nonzero mark is decremented and the character's eight lines (PixelBuffer, from line 7 up, 32 bytes apart) go to the screen.

Then the 640 colours of ColourBuffer `$E600` to the attributes `$5800` (rows 0-19) in one `LDIR`.

From MainLoop (`$85AB`), every pass. A mark of 2 (an explosion, HighlightCell) draws the character on two passes.

Witness: L1 117170 (c1, c1g, cheat, controls, corner, energy, energy-out, hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x59).

[Animation: `CopyPlayArea` at work](img/routines/CopyPlayArea.gif)

| | |
| --- | --- |
| Runs (c1g: the c1 recording's game window, from the jump to `$8382` (frame 15752 T 33930): the menu and play) | 1,043 calls, 67,445,630 t-states own (20.07 %) |
| Runs (the other recordings) | 115,258 calls (`stage2/rec/energy-out` 6,304, `stage1/energy` 6,268, `docs/integrate/rec/nameedit` 5,155 and 87 more) |
| Called from | `MainLoop` |
| Calls | `CopyPlayAreaThird` (falls into) |
| Reads | `$E300`-`$E57F` (`work space $E300+`); `$E600`-`$E87F` (`work space $E600+`); `$E900`-`$FCFF` (`work space $E900+`) |
| Writes | `$4000`-`$507F` (screen); `$5100`-`$517F` (screen); `$5200`-`$527F` (screen); `$5300`-`$537F` (screen); `$5400`-`$547F` (screen); `$5500`-`$557F` (screen); 4 more ranges |

### `CopyPlayAreaThird` (`$8C19`)

**The marks' page (a screen third) in C, the screen's page in B: on with the next character**

Part of CopyPlayArea. An entry of its own: the `mine` and `overload` recordings start inside the loop (CopyPlayAreaNext `$8C56` is their root), and the walk shares these jump targets with CopyPlayArea.

Witness: L1 351508 (c1, c1g, cheat, controls, corner, energy, energy-out, gameover, hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x59).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1,154 calls (`stage1/mine` 577, `stage1/overload` 577) |
| Called from | `CopyPlayArea` (falls into), `CopyPlayAreaNext` (tail) |
| Calls | `CopyPlayAreaLoop` (falls into) |

### `CopyPlayAreaLoop` (`$8C1A`)

**The next mark: zero, skip; else count it down and copy the character's eight lines**

Part of CopyPlayArea (see CopyPlayAreaThird).

Witness: L1 74988317 (c1, c1g, cheat, controls, corner, energy, energy-out, gameover, hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x59).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 246,648 calls (`stage1/mine` 123,324, `stage1/overload` 123,324) |
| Called from | `CopyPlayAreaThird` (falls into), `CopyPlayAreaNext` (tail) |
| Calls | `CopyPlayAreaNext` (falls into) |
| Reads | `$E300`-`$E57F` (`work space $E300+`); `$E900`-`$FCFF` (`work space $E900+`) |
| Writes | `$4000`-`$507F` (screen); `$5100`-`$517F` (screen); `$5200`-`$527F` (screen); `$5300`-`$537F` (screen); `$5400`-`$547F` (screen); `$5500`-`$557F` (screen); 3 more ranges |

### `CopyPlayAreaNext` (`$8C56`)

**Still in the row: the next character; else the row above, the third below at a page's end**

Part of CopyPlayArea. An entry of its own: the `gameover`, `mine` and `overload` recordings start from snapshots taken here, so their L1s mark a routine root.

Witness: L1 74988314 (c1, c1g, cheat, controls, corner, energy, energy-out, gameover, hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x59).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 246,648 calls (`stage1/mine` 123,324, `stage1/overload` 123,324) |
| Called from | `CopyPlayAreaLoop` (falls into) |
| Calls | `CopyPlayAreaThird` (tail), `CopyPlayAreaLoop` (tail) |
| Reads | `$E300`-`$E4BB` (`work space $E300+`); `$E600`-`$E87F` (`work space $E600+`); `$EA15`-`$EA16` (`work space $EA15+`); `$EA35`-`$EA36` (`work space $EA35+`); `$EA55`-`$EA56` (`work space $EA55+`); `$EA75`-`$EA76` (`work space $EA75+`); 44 more ranges |
| Writes | `$4035`-`$4036` (screen); `$4055`-`$4056` (screen); `$40A5`-`$40A6` (screen); `$40C5`-`$40C6` (screen); `$4135`-`$4136` (screen); `$4155`-`$4156` (screen); 49 more ranges |

### `WipeInScreen` (`$8C95`)

**Wipe the full-screen buffer (`$E500` / `$E200`) onto the screen from a random corner**

WipeWidth = 9, WipeTable = ScreenWipes `$8DD5`; then WipeIn. From the menu (`$9CA3`, `$A758`).

Witness: L1 14 (c1, c1g, controls, energy, energy-out, hof, kempston, menu, nameedit, practice, rzx344752).

| | |
| --- | --- |
| Runs (c1g: the c1 recording's game window, from the jump to `$8382` (frame 15752 T 33930): the menu and play) | 1 call, 58 t-states own (0.00 %) |
| Runs (the other recordings) | 13 calls (`stage1/controls` 3, `stage1/menu` 2, `stage1/rzx/r344752` 1 and 7 more) |
| Called from | `HallOfFame`, `OptionsMenu` |
| Calls | `WipeIn` (tail) |
| Reads | `$8C78`-`$8C94` (`WipeSteps`, `WipeRows`, `WipeWidth`, `WipeTable` and 1 more); `$8E05`-`$8E14` (`ScreenWipes+48`); `$E200`-`$FCFF` (`work space $E200+`) |
| Writes | `$4000`-`$5AFF` (screen); `$8C78`-`$8C94` (`WipeSteps`, `WipeRows`, `WipeWidth`, `WipeTable` and 1 more) |

### `WipeInPlayArea` (`$8CA2`)

**Wipe the play buffers (`$E900` / `$E600`) onto the screen's rows 0-19 from a random corner**

WipeWidth = 13, WipeTable = PlayAreaWipes `$8D95`; falls into WipeIn. From SetUpLevel (`$8512`).

Witness: L1 200 (c1, c1g, cheat, controls, energy, energy-out, hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x59).

[Animation: `WipeInPlayArea` at work](img/routines/WipeInPlayArea.gif)

| | |
| --- | --- |
| Runs (c1g: the c1 recording's game window, from the jump to `$8382` (frame 15752 T 33930): the menu and play) | 1 call, 46 t-states own (0.00 %) |
| Runs (the other recordings) | 196 calls (`stage1/menu` 61, `stage1/rzx/r024486` 3, `stage1/rzx/r183540` 3 and 87 more) |
| Called from | `SetUpLevel` |
| Calls | `WipeIn` (falls into) |
| Reads | `$8C78`-`$8C94` (`WipeSteps`, `WipeRows`, `WipeWidth`, `WipeTable` and 1 more); `$8D95`-`$8DD4` (`PlayAreaWipes`); `$E600`-`$E87F` (`work space $E600+`); `$E900`-`$FCFF` (`work space $E900+`) |
| Writes | `$4000`-`$577F` (screen); `$5800`-`$5A7F` (screen); `$8C78`-`$8C94` (`WipeSteps`, `WipeRows`, `WipeWidth`, `WipeTable` and 1 more) |

### `WipeIn` (`$8CAD`)

**Grow a rectangle of the buffer on the screen from a corner, one row and one column a round**

Random `$8E15`: L AND 3 picks one of the table's four records (a corner), copied to WipeSteps. WipeRows = 1. Each round: the four addresses saved; WipeRows character rows of WipeWidth bytes are copied (eight lines from the linear buffer, 32 bytes a line, to the screen; one attribute row from the colour buffer); a pause of (33 - WipeWidth) x 255 `DJNZ` (the rounds speed up); the addresses back, plus their steps; WipeRows + 1 and WipeWidth + 1 until the width passes 32.

The steps move the screen corner and the source corner so that the picture slides in: from the top-left the screen corner stays and the source runs from the buffer's bottom-right part to its top-left (`$FEFF` = up one row and left one byte); at the end the whole buffer is on the screen. The play area: 13 x 1 to 32 x 20 in 20 rounds; the full screen: 9 x 1 to 32 x 24 in 24.

Witness: L1 214 (c1, c1g, cheat, controls, energy, energy-out, hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x60).

| | |
| --- | --- |
| Runs (c1g: the c1 recording's game window, from the jump to `$8382` (frame 15752 T 33930): the menu and play) | 2 calls, 5,338,832 t-states own (1.59 %) |
| Runs (the other recordings) | 91 calls (`stage1/menu` 63, `stage1/controls` 6, `docs/integrate/rec/nameedit` 4 and 6 more) |
| Called from | `WipeInScreen` (tail), `WipeInPlayArea` (falls into) |
| Calls | `Random` |
| Reads | `$8C78`-`$8C94` (`WipeSteps`, `WipeRows`, `WipeWidth`, `WipeTable` and 1 more); `$8D95`-`$8DF4` (`PlayAreaWipes`, `ScreenWipes`); `$8E05`-`$8E14` (`ScreenWipes+48`); `$E200`-`$FCFF` (`work space $E200+`) |
| Writes | `$4000`-`$5AFF` (screen); `$8C78`-`$8C94` (`WipeSteps`, `WipeRows`, `WipeWidth`, `WipeTable` and 1 more) |

### `Random` (`$8E15`)

**The next random number: RandomSeed = 254 x (RandomSeed + 1) mod 65537 - 1; HL = the new seed**

H = E, L = `$FD`, then three subtractions with borrows: 256 x seed - 2 x seed + 253 taken modulo 65537 (`$10001`) and folded to 16 bits, the Lehmer generator of the Spectrum ROM's RND with 254 for its 75. Checked against that formula for all 65 536 seeds (work/ann/01-main/rnd_check.py); the period is 65 536.

Callers: WipeIn (the corner), the grey grid (`$9014`, the scatter), the charging's scramble (`$A587`), the noise sound (`$A896`), the gremlins (`$ABED`, `$AC31`, `$AC53`). The options panel's key wait adds 1 to the seed on each of its loops (`$A7AB-$A7AF`), so the game's random numbers depend on how long the panel waited; `$ACA0` reads the seed's high byte.

Witness: L1 826505 (c1, c1g, cheat, controls, corner, energy, energy-out, hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x60).

| | |
| --- | --- |
| Runs (c1g: the c1 recording's game window, from the jump to `$8382` (frame 15752 T 33930): the menu and play) | 4,322 calls, 635,681 t-states own (0.19 %) |
| Runs (the other recordings) | 809,152 calls (`docs/integrate/rec/nameedit` 22,245, `stage2/rec/hof` 22,245, `stage1/rzx/r183540` 19,762 and 88 more) |
| Called from | `WipeIn`, `PrismTurn`, `ChargeLaser`, `PlayNoise`, `GremlinAppear`, `GremlinTurnMirror`, `GremlinMove` |
| Reads | `$8E32`-`$8E33` (`RandomSeed`) |
| Writes | `$8E32`-`$8E33` (`RandomSeed`) |

### `PrintFull` (`$8E3A`)

**Print the text records at HL into the full-screen buffer (pixels `$E500`, attributes `$E200`)**

PrintPixelPage = `$E5`, PrintColourPage = `$E2`; then PrintRecords (in PrintPlay). From the hall of fame (`$9F2B`-`$9F3D`) and the ending (`$A8D1`).

Witness: L1 74 (c1, c1g, controls, ending, energy-out, gameover, hof, kempston, menu, mine, nameedit, overload, rzx344752).

| | |
| --- | --- |
| Runs (c1g: the c1 recording's game window, from the jump to `$8382` (frame 15752 T 33930): the menu and play) | 4 calls, 177,160 t-states own (0.05 %) |
| Runs (the other recordings) | 70 calls (`stage1/controls` 12, `stage1/rzx/r344752` 9, `docs/integrate/rec/nameedit` 8 and 9 more) |
| Called from | `DrawMenuScreen`, `EndingScreen` |
| Reads | `$8E34`-`$8E39` (`PrintPixel`, `PrintPixelPage`); `$9F49`-`$A052` (`HallOfFameTitle`, `OptionsText`, `NameCursorGlyph`, `HallOfFameScores` and 1 more); `$A984`-`$AA86` (`EndingText`); `$D200`-`$D20F` (`Font`); `$D240`-`$D24F` (`Font+64`); `$D260`-`$D26F` (`Font+96`); 3 more ranges |
| Writes | `$8E34`-`$8E39` (`PrintPixel`, `PrintPixelPage`); `$E228`-`$E256` (`work space $E228+`); `$E2A9`-`$E30A` (`work space $E2A9+`); `$E321`-`$E37D` (`work space $E321+`); `$E392`-`$E3DD` (`work space $E392+`); `$E401`-`$E40C` (`work space $E401+`); 10 more ranges |

### `PrintPlay` (`$8E47`)

**Print the text records at HL into the play buffers (pixels `$E900`, colours `$E600`)**

PrintPixelPage = `$E9`, PrintColourPage = `$E6`, then the records. A record: the attribute with bit 7 set, the column, the character row (into the buffer: the pixels at page + row, the colour at page x 256 + 32 x row + column), then the characters (32 up, eight lines from Font: `$D200` + 8 x (code - 32), 32 bytes apart) until a byte with bit 7: the next record, or `$FF`, the end.

The colour is written for every character but `/` and `\` (`$2F`, `$5C`), which keep the colour under them.

PrintPlay's own part runs only for PracticeText (DrawMarkedChars `$8A71`), in practice (the `practice` recording); PrintRecords runs for both.

Witness: L1 615 (practice).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 615 calls (`docs/dfA/rec/practice` 615) |
| Called from | `DrawMarkedChars` |
| Reads | `$8A9D`-`$8AC0` (`PracticeText`); `$8E34`-`$8E39` (`PrintPixel`, `PrintPixelPage`); `$D200`-`$D207` (`Font`); `$D270`-`$D277` (`Font+112`); `$D308`-`$D34F` (`Font+264`); `$D368`-`$D3AF` (`Font+360`) |
| Writes | `$8E34`-`$8E39` (`PrintPixel`, `PrintPixelPage`); `$E860`-`$E87F` (`work space $E860+`); `$FC00`-`$FCFF` (`work space $FC00+`) |

## entry

`src/game/entry.asm`

### `GameEntry` (`$8382`)

**The game's entry: JP Start**

The mover of the last loader stage jumps here after moving the game to `$6000-$DFFF` (SP = `$FFFF`). One `JP` over the per-level table LevelSettings to Start `$8408`.

Run once a load (`c1` and its game window `c1g`; the first instruction of `c1g`).

Witness: L1 2 (c1, c1g).

| | |
| --- | --- |
| Runs (c1g: the c1 recording's game window, from the jump to `$8382` (frame 15752 T 33930): the menu and play) | run into, not called, 10 t-states own (0.00 %) |
| Runs (the other recordings) | 1 call (`stage1/c1` 1) |
| Calls | `Start` (tail) |

### `Start` (`$8408`)

**Interrupts off, IM 2 on (the jump at `$FDFD` and the vector table), then into TitleLoop**

`DI`, then `$A2FA` (the IM 2 set-up: `JP $A32A` at `$FDFD`, the table `$FE00-$FF00`, I = `$FE`). Falls into TitleLoop; interrupts stay off until LevelPanel's `EI` (`$843B`).

Run once a load (`c1`, `c1g`).

Witness: L1 2 (c1, c1g).

| | |
| --- | --- |
| Runs (c1g: the c1 recording's game window, from the jump to `$8382` (frame 15752 T 33930): the menu and play) | 1 call, 12,578 t-states own (0.00 %) |
| Runs (the other recordings) | 1 call (`stage1/c1` 1) |
| Called from | `GameEntry` (tail) |
| Calls | `SetupInterrupts` |
| Reads | `$81FF` (`Level`); `$8385`-`$8386` (`LevelSettings`); `$8407` (`PracticeFlag`); `$88B0`-`$88BF` (`LevelDigits`); `$8912`-`$8913` (`LevelAddress`); `$9B44`-`$9B48` (`SavedScore`); 1 more ranges |
| Writes | `$50A6`-`$50A7` (screen); `$51A6`-`$51A7` (screen); `$52A6`-`$52A7` (screen); `$53A6`-`$53A7` (screen); `$53BA`-`$53BF` (screen); `$5486`-`$5487` (screen); 19 more ranges |

### `TitleLoop` (`$840C`)

**Demo and practice off, the hall-of-fame check, the title and options panel, then a new game**

The place every game ends: GameOver (`$8711`), the demo's last level (`$856E`), the end of practice (`$887F`), the ending (`$88AD`) and the abort keys (`$982C`) jump here.

Clears the demo flag `$8379` and PracticeFlag; `$9BC0` (the score `$9B3E` against the hall of fame, the name entry); `$A729` (the title, the options panel; it returns when a game is to start, with `$8379` set by key 5 DEMO or PracticeFlag by key 6). Falls into NewGame.

Witness: L1 15 (c1, c1g, controls, energy-out, gameover, hof, kempston, menu, mine, nameedit, overload, rzx344752).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 13 calls (`stage1/controls` 3, `stage1/menu` 2, `docs/integrate/rec/nameedit` 1 and 7 more) |
| Called from | `MainLoop` (tail), `LoseLifeDrained` (tail), `LevelCompletePause` (tail), `ReadKeys` (tail) |
| Calls | `HallOfFame`, `TitleScreen` |
| Reads | `$81FF` (`Level`); `$8385`-`$8386` (`LevelSettings`); `$8407` (`PracticeFlag`); `$88B0`-`$88BF` (`LevelDigits`); `$8912`-`$8913` (`LevelAddress`); `$9B44`-`$9B48` (`SavedScore`); 1 more ranges |
| Writes | `$50A6`-`$50A7` (screen); `$51A6`-`$51A7` (screen); `$52A6`-`$52A7` (screen); `$53A6`-`$53A7` (screen); `$53BA`-`$53BF` (screen); `$5486`-`$5487` (screen); 19 more ranges |

### `NewGame` (`$8419`)

**Three lives, the first level (or practice slot 60), the saved score cleared, then LevelPanel**

Lives `$837D` = 3; Level `$81FF` = 0, or `$3C` (P1) when PracticeFlag is set; two Delays (about 24 frames); `$9B30` clears the score saved at the level's start (`$9B44`, five spaces), so SetUpLevel starts the game's score at 0. Falls into LevelPanel.

An entry of its own: the `energy` and `kempston` recordings start from a snapshot taken inside `$A729`, so their L1s mark a routine root here.

Witness: L1 11 (c1, c1g, controls, energy, energy-out, kempston, menu, practice).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings run into, not called (`stage1/kempston`, `docs/dfA/rec/practice`, `stage1/energy` and 1 more) |
| Calls | `Delay` |
| Reads | `$81FF` (`Level`); `$8385`-`$8386` (`LevelSettings`); `$83FD`-`$8407` (`LevelSettings+120`, `PracticeFlag`); `$88B0`-`$88BF` (`LevelDigits`); `$8900`-`$8913` (`LevelDigits+80`, `Delay`, `DelayOuter`, `DelayInner` and 1 more); `$9B44`-`$9B48` (`SavedScore`); 2 more ranges |
| Writes | `$50A6`-`$50A7` (screen); `$51A6`-`$51A7` (screen); `$52A6`-`$52A7` (screen); `$53A6`-`$53A7` (screen); `$53BA`-`$53BF` (screen); `$5486`-`$5487` (screen); 18 more ranges |

### `NewGameDelay2` (`$842C`)

**NewGameDelay2**

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings run into, not called (`stage2/rec/L01`) |
| Calls | `Delay`, `ClearSavedScore` |
| Reads | `$81B8`-`$81D0` (`ExplosionSlots`); `$81FF` (`Level`); `$8376`-`$8386` (`BeamStartX`, `BeamStartY`, `BeamStartDirection`, `DemoFlag` and 10 more); `$8407` (`PracticeFlag`); `$88B0`-`$88BF` (`LevelDigits`); `$8912`-`$8913` (`LevelAddress`); 8 more ranges |
| Writes | `$50A6`-`$50A7` (screen); `$51A6`-`$51A7` (screen); `$52A6`-`$52A7` (screen); `$53A6`-`$53A7` (screen); `$53BA`-`$53BF` (screen); `$5486`-`$5487` (screen); 30 more ranges |

### `LevelPanel` (`$8432`)

**Draw the bottom panel afresh, blank the COMPUTER line, interrupts on; into SetUpLevel**

From NewGame and LevelCompletePause (`$8882`, after a level's bonus). `$A50C` copies the panel's picture `$7B80` (four character rows, the LEVEL, LIVES, OVERLOAD, ENERGY, SCORE, HIGH and COMPUTER fields, three full life bars) to the screen's rows 20-23 with its attributes; MessageText `$A10E` = `$A199` (a blank line of three spaces that loops); `EI`. Falls into SetUpLevel.

Witness: L1 92 (c1, c1g, controls, energy, energy-out, hof, kempston, menu, nameedit, practice, L x20, rzx x59).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 80 calls (`stage1/rzx/r154293` 1, `stage1/rzx/r215327` 1, `stage1/rzx/r183540` 1 and 77 more) |
| Called from | `LevelCompletePause` (tail) |
| Calls | `SetUpLevel` (falls into), `DrawPanel` |
| Reads | `$5800`-`$5A7E` (screen); `$81B8`-`$81D0` (`ExplosionSlots`); `$81FF` (`Level`); `$8376`-`$8407` (`BeamStartX`, `BeamStartY`, `BeamStartDirection`, `DemoFlag` and 11 more); `$88B0`-`$88FF` (`LevelDigits`); `$8912`-`$8913` (`LevelAddress`); 9 more ranges |
| Writes | `$50A6`-`$50A7` (screen); `$51A6`-`$51A7` (screen); `$52A6`-`$52A7` (screen); `$53A6`-`$53A7` (screen); `$53BA`-`$53BF` (screen); `$5486`-`$5487` (screen); 20 more ranges |

## levels

`src/game/levels.asm`

### `BuildLevel` (`$891A`)

**Copy level Level to the grid, clear the character map, mark every character; into RenderGrid**

1. LevelAddress = LevelData `$B000` + `$87` x Level (by Level additions of `$87`).

2. LevelGrid `$FD00-$FDFA` cleared: the row above the grid (`$FD12`), the guards and whatever the mover left there.

3. The character map `$E000-$E2FF` cleared (20 rows of 32 and 256 bytes after it); DrawMarks `$E300-$E5FF` set to 1: every character of the play area is drawn on the next DrawMarkedChars and copied once by CopyPlayArea.

4. The 135 level bytes go to `$FD23` in 9 rows of 15, each row followed by two zero guards (17 bytes a row): the cell (row r, column c) is at `$FD23` + 17 r + c, and the row above (r = -1) and the guards read as empty cells.

5. Falls into RenderGrid (and so DrawMarkedChars): the whole level is drawn into the buffers.

Called by SetUpLevel (`$8509`) only. The tool `tools/level_maps.py` runs it in SkoolKit's simulator for every slot (docs/img/maps).

Witness: L1 200 (c1, c1g, cheat, controls, energy, energy-out, hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x59).

[Animation: `BuildLevel` at work](img/routines/BuildLevel.gif)

| | |
| --- | --- |
| Runs (c1g: the c1 recording's game window, from the jump to `$8382` (frame 15752 T 33930): the menu and play) | 1 call, 40,782 t-states own (0.01 %) |
| Runs (the other recordings) | 196 calls (`stage1/menu` 61, `stage1/rzx/r319697` 3, `stage1/rzx/r307588` 3 and 87 more) |
| Called from | `SetUpLevel` |
| Calls | `RenderGrid` (falls into) |
| Reads | `$81FF` (`Level`); `$8912`-`$8913` (`LevelAddress`); `$B000`-`$D02A` (`LevelData`); `$E000`-`$E5FE` (`work space $E000+`); `$FD00`-`$FDF9` (`work space $FD00+`) |
| Writes | `$8912`-`$8913` (`LevelAddress`); `$E000`-`$E5FF` (`work space $E000+`); `$FD00`-`$FDFA` (`work space $FD00+`) |

## elements

`src/game/elements.asm`

### `CursorFire` (`$9A57`)

**Fire: the square cursor, and a gremlin in the cell under the cursor is killed (160 points each)**

Called each pass by the main loop (`$859E`). Fire is the control bits' bit 4 (`$96C5`) or read again by the method (keyboard: any key of the bottom rows; Sinclair: 5 or 0; Kempston: bit 4 of port `$1F`; Protek: 0). With fire: CursorMode `$96C6` = 7, and the gremlin records (`$AB63`, 6 bytes each, `$AB95` of them, the count the level set-up copies from the second byte of its `$8385` pair) are searched for one whose cell address (+4, +5) is the cursor cell's. Each found one is killed: +0 = `$C8`, +1 = 0, +5 = 0 (no cell), `$837C` = `$FF` (the main loop then plays the effect `$81ED`), and the score gets 16 tens for it (`AddScore` `$9AF3`).

Recordings: `$9AC5` 117 180 runs in 53 RZX segments; a gremlin was hit (`$9AD1`) 120 times in 43 segments.

Witness: L1 117171 (c1, c1g, cheat, controls, corner, energy, energy-out, hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x59).

| | |
| --- | --- |
| Runs (c1g: the c1 recording's game window, from the jump to `$8382` (frame 15752 T 33930): the menu and play) | 1,043 calls, 153,707 t-states own (0.05 %) |
| Runs (the other recordings) | 115,259 calls (`stage2/rec/energy-out` 6,304, `stage1/energy` 6,268, `docs/integrate/rec/nameedit` 5,155 and 87 more) |
| Called from | `MainLoop` |
| Calls | `AddScore` |
| Reads | `$81FD` (`ControlMethod`); `$96C3`-`$96C5` (`CursorVars`, `CursorY`, `ControlBits`); `$AB67`-`$AB95` (`Gremlins+4`, `GremlinNewX`, `GremlinNewY`, `GremlinCount`) |
| Writes | `$837C` (`GremlinSoundFlag`); `$96C6` (`CursorMode`); `$AB63`-`$AB8C` (`Gremlins`) |
| Ports in | `$021F`, `$7EFE`, `$EFFE`, `$F7FE` |

### `ResetBars` (`$A52F`)

**At each level start: both bars empty, the pointers, LaserCharging on, CHARGING LASER (or DEMO)**

Clears the 8 bytes of the overload bar (`$54B1`) and of the energy bar (`$54F1`) in their three pixel rows, OverloadBarPointer = `$54B1`, EnergyBarPointer = `$54F1`, LaserCharging = `$FF`, MessageNumber = 1, and MessageText = ChargingMessage; in the demo (`$8379` set) DemoMessage on level 0 only (on later demo levels the message is left as it is).

Called by `$843C` (at `$8515`) at each level start and restart after a lost life. Evidence: 164 runs (all recordings but `gameover`).

Witness: L1 200 (c1, c1g, cheat, controls, energy, energy-out, hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x59).

| | |
| --- | --- |
| Runs (c1g: the c1 recording's game window, from the jump to `$8382` (frame 15752 T 33930): the menu and play) | 1 call, 1,124 t-states own (0.00 %) |
| Runs (the other recordings) | 196 calls (`stage1/menu` 61, `stage1/controls` 3, `stage1/rzx/r183540` 3 and 87 more) |
| Called from | `SetUpLevel` |
| Reads | `$81FF` (`Level`); `$8379` (`DemoFlag`) |
| Writes | `$54B1`-`$54B8` (screen); `$54F1`-`$54F8` (screen); `$55B1`-`$55B8` (screen); `$55F1`-`$55F8` (screen); `$56B1`-`$56B8` (screen); `$56F1`-`$56F8` (screen); 2 more ranges |

### `ChargeLaser` (`$A57A`)

**A pass of the laser's charge: turn the mirrors at random, the energy bar + 2 steps; full: the play starts**

From DrainEnergy while LaserCharging is set, once a pass. For each of the 9 x 15 cells of the grid (`$FD23`, 17 bytes a row) that holds a mirror (`$01-$10`) it draws a random pair from `$8E15` (C = its H): bit 0 set turns the mirror (with 30 mirrors or more on the level, `$837A`, bits 1 and 2 must be set too: 1 in 8 rather than 1 in 2), bit 3 chooses the way (+1 or -1 of 16 angles, kept in `$01-$10`), and the cell's four characters are marked for redraw in DrawMarks (`$E321`, 2 a mark). So every level starts with its mirrors scrambled.

Then SoundFlags bit 4 (the charge's tone, every frame) and two bits into the energy bar (`SCF; RRA` twice: it fills from the left); a full byte moves EnergyBarPointer right. At `$54F9` the bar is full: the pointer back to `$54F8`, EnergyTick and LaserCharging 0, MessageText = BlankMessage, SoundFlags 0, and the sound `$81F2` (PlaySound, 18 frames).

32 passes a level start (8 bytes of 4 steps): `rzx-011752` frames 230-382.

Evidence: 3328 runs (104 level starts x 32).

Witness: L1 4480 (c1, c1g, cheat, controls, energy, energy-out, hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x59).

| | |
| --- | --- |
| Runs | ran within another entry's routine (reached by a jump or by running on, its calls below), no runs of its own counted |
| Calls | `Random`, `PlaySound` |

### `DrainEnergy` (`$A613`)

**Each pass: the charge while LaserCharging, else critical / low / drained and a step every rate frames**

Called by the main loop `$854A` at `$85C9`, once a pass. While LaserCharging is set: ChargeLaser. Else:

- EnergyBarPointer at `$54F1` (one byte left): `$837E` = `$FF` (the main loop then flashes the beam with bit 3 of FrameCounter, `$8587`) and ENERGY LEVEL CRITICAL (MessageNumber `$0C`) unless a more urgent one is shown;

- EnergyTick below the rate (the operand of `CP` at EnergyRate `$A63B`, written by the level set-up `$84D2` from the table `$8385`): return. Else EnergyTick = 0 and the bar loses a step (`SLA` of its byte in three rows: it shrinks from the right); an empty byte moves the pointer left: at `$54F2` ENERGY LOW (`$0A`), at `$54F0` EnergyDrained.

So a level lasts 64 steps of `rate` frames (level 1: `$5A` = 90, 5760 frames, 115 s, plus the pass's wait). `energy`: charged at about frame 690, drained at 6450. The POKE "Infinite Energy" (`$A63D`, `RET C` made `RET`) stops it here.

Evidence: 90 776 runs.

Witness: L1 117106 (c1, c1g, cheat, controls, corner, energy, energy-out, hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x59).

| | |
| --- | --- |
| Runs (c1g: the c1 recording's game window, from the jump to `$8382` (frame 15752 T 33930): the menu and play) | 1,043 calls, 769,588 t-states own (0.23 %) |
| Runs (the other recordings) | 115,193 calls (`stage2/rec/energy-out` 6,301, `stage1/energy` 6,266, `docs/integrate/rec/nameedit` 5,152 and 87 more) |
| Called from | `PassEnd` |
| Reads | `$54F1`-`$54F8` (screen); `$837A` (`MirrorCount`); `$A104` (`MessageNumber`); `$A506`-`$A509` (`EnergyTick`, `EnergyBarPointer`, `LaserCharging`); `$A8A6` (`SoundFlags`); `$FD23`-`$FDB9` (`work space $FD23+`) |
| Writes | `$54F1`-`$54F8` (screen); `$55F1`-`$55F8` (screen); `$56F1`-`$56F8` (screen); `$8378`-`$837E` (`BeamStartDirection`, `DemoFlag`, `MirrorCount`, `BurnSoundFlag` and 3 more); `$8ED3` (`LifeLost`); `$A104`-`$A10F` (`MessageNumber`, `MessageGlyph`, `MessageState`, `MessageText`); 4 more ranges |

### `UpdateOverload` (`$A683`)

**Each pass: the beam on a mine (MINE ALERT, 4 steps), in the laser (OVERLOAD, 1 step), else cool down**

Called by the main loop at `$85BF`. BeamOnMine `$8ED4` (set by the beam `$8F6C`): MessageNumber `$13`, MineAlertMessage, then OverloadStep and three more OverloadAddStep. BeamInLaser `$8ED5`: SoundFlags bit 2 on and bit 1 off, OVERLOAD (`$12`) unless a more urgent message other than MINE ALERT is shown, OverloadStep. Neither: CoolOverload.

Evidence: 90 821 runs; MINE ALERT 1753 (`mine`, `gameover`, 46 RZX segments), OVERLOAD (`$A6A6`) in `overload` and the RZX segments.

Witness: L1 117162 (c1, c1g, cheat, controls, corner, energy, energy-out, gameover, hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x59).

| | |
| --- | --- |
| Runs (c1g: the c1 recording's game window, from the jump to `$8382` (frame 15752 T 33930): the menu and play) | 1,043 calls, 249,665 t-states own (0.07 %) |
| Runs (the other recordings) | 115,249 calls (`stage2/rec/energy-out` 6,304, `stage1/energy` 6,268, `docs/integrate/rec/nameedit` 5,155 and 88 more) |
| Called from | `PassEnd` |
| Calls | `OverloadStep` (falls into), `OverloadAddStep` (tail) |
| Reads | `$54B1`-`$54B8` (screen); `$8407` (`PracticeFlag`); `$8ED4`-`$8ED5` (`BeamOnMine`, `BeamInLaser`); `$A104` (`MessageNumber`); `$A50A`-`$A50B` (`OverloadBarPointer`); `$A8A6` (`SoundFlags`) |
| Writes | `$54B1`-`$54B8` (screen); `$55B1`-`$55B8` (screen); `$56B1`-`$56B8` (screen); `$8ED3`-`$8ED5` (`LifeLost`, `BeamOnMine`, `BeamInLaser`); `$A104`-`$A10F` (`MessageNumber`, `MessageGlyph`, `MessageState`, `MessageText`); `$A50A`-`$A50B` (`OverloadBarPointer`); 1 more ranges |

### `OverloadStep` (`$A6C6`)

**Clear BeamOnMine and BeamInLaser for the next pass, then one step**

The beam sets the two flags again on each pass it meets a mine or the laser. Evidence: 8226 runs.

Witness: L1 9141 (gameover, hof, mine, nameedit, overload, L x20, rzx x55).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 7,880 calls (`stage1/rzx/r295329` 357, `stage1/rzx/r268227` 331, `stage1/rzx/r204297` 312 and 63 more) |
| Called from | `UpdateOverload` (falls into) |
| Calls | `OverloadAddStep` (falls into) |
| Writes | `$8ED4`-`$8ED5` (`BeamOnMine`, `BeamInLaser`) |

### `OverloadAddStep` (`$A6CD`)

**One step on the overload bar; full (`$54B9`): LifeLost, unless practice**

Returns at once when the bar is full (OverloadBarPointer `$54B9`). The POKE "Infinite Time" turns this `RET Z` at `$A6D3` into `RET`: the bar never fills. Else one bit into the byte (`SCF; RRA` in three rows: it fills from the left); a full byte moves the pointer right; at `$54B9` LifeLost `$8ED3` = `$FF` unless PracticeFlag `$8407` is set.

Evidence: 13 485 runs; full (`$A6EE`) 41 times (`mine`, `overload`, `gameover`, 24 RZX segments).

Witness: L1 15402 (gameover, hof, mine, nameedit, overload, L x20, rzx x55).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 14,141 calls (`stage1/rzx/r327592` 743, `stage1/rzx/r281507` 472, `stage1/rzx/r210323` 471 and 63 more) |
| Called from | `UpdateOverload` (tail), `OverloadStep` (falls into) |
| Reads | `$54B1`-`$54B8` (screen); `$8407` (`PracticeFlag`); `$A50A`-`$A50B` (`OverloadBarPointer`) |
| Writes | `$54B1`-`$54B8` (screen); `$55B1`-`$55B8` (screen); `$56B1`-`$56B8` (screen); `$8ED3` (`LifeLost`); `$A50A`-`$A50B` (`OverloadBarPointer`) |

### `CoolOverload` (`$A6F4`)

**Neither mine nor laser: the two tones off, OVERLOAD / MINE ALERT taken off, one step back**

From UpdateOverload. SoundFlags bits 1 and 2 cleared; MessageNumber `$12` or `$13`: 0 and BlankMessage. The bar's byte shifted left (a step back); an empty byte moves OverloadBarPointer left, not below `$54B1`.

Evidence: 82 595 runs.

Witness: L1 108021 (c1, c1g, cheat, controls, corner, energy, energy-out, hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x59).

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `UpdateGremlins` (`$AB9F`)

**Each pass: count the waiting gremlins down, make them appear, walk or turn the others, draw them**

Called by the main loop (`$85A8`) when the laser is charged. GremlinPhase + `$20` (the next frame, `RES 7`). For each of GremlinCount records (IX = Gremlins, 6 bytes each): delay `$FF`: skip; delay not 0: on passes with GremlinPhase bit 5 clear count it down, at 0 GremlinAppear; delay 0: turns left: GremlinTurnMirror, else GremlinMove, then DrawGremlin.

So the first gremlin appears 2 x 65 passes after the charge (`rzx-011752`, level 3: the charge ends at frame 382, the first GremlinAppear at 850), the next ones 20 passes apart.

Evidence: 87 502 runs; GremlinAppear in 54 RZX segments.

Witness: L1 112691 (c1, c1g, cheat, controls, corner, energy, energy-out, hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x59).

| | |
| --- | --- |
| Runs (c1g: the c1 recording's game window, from the jump to `$8382` (frame 15752 T 33930): the menu and play) | 1,011 calls, 83,932 t-states own (0.02 %) |
| Runs (the other recordings) | 110,907 calls (`stage2/rec/energy-out` 6,208, `stage1/energy` 6,172, `docs/integrate/rec/nameedit` 5,059 and 87 more) |
| Called from | `MainLoop` |
| Calls | `GremlinAppear`, `GremlinTurnMirror`, `GremlinMove`, `DrawGremlin` |
| Reads | `$AB63`-`$AB96` (`Gremlins`, `GremlinNewX`, `GremlinNewY`, `GremlinCount` and 1 more) |
| Writes | `$AB63`-`$AB96` (`Gremlins`, `GremlinNewX`, `GremlinNewY`, `GremlinCount` and 1 more) |

### `GremlinAppear` (`$ABED`)

**A random empty cell in columns 3-10, rows 0-7: the gremlin is there; BEWARE OF THE GREMLINS**

X = 2 x ((L AND 7) + 3), Y = 2 x (H AND 7) from `$8E15`; the cell `$FD12 + 17 x (row + 1) + column`. Not empty: delay = 1 (another try on the next counted pass). Empty: GremlinsMessage (MessageNumber 4) unless a more urgent one is shown, and DrawGremlin.

Evidence: 4910 runs (54 RZX segments); the message 253 times.

Witness: L1 5150 (hof, nameedit, L x18, rzx x54).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 5,150 calls (`stage1/rzx/r154293` 1,506, `stage1/rzx/r017741` 1,409, `stage1/rzx/r335610` 604 and 71 more) |
| Called from | `UpdateGremlins` |
| Calls | `Random`, `DrawGremlin` (tail) |
| Reads | `$A104` (`MessageNumber`); `$FD26`-`$FDA4` (`work space $FD26+`) |
| Writes | `$A104`-`$A10F` (`MessageNumber`, `MessageGlyph`, `MessageState`, `MessageText`); `$AB63`-`$AB90` (`Gremlins`) |

### `GremlinTurnMirror` (`$AC2D`)

**One turn of the mirror under the gremlin: +1 or -1 of 16 angles at random**

Turns - 1; the cell at +4/+5 gets (code AND `$0F`) + 1 (one way) or (code - 2 AND `$0F`) + 1 (the other), by bit 0 of `$8E15`'s L. The beam and the redraw see the new angle on the next pass.

Evidence: 11 188 runs (52 RZX segments).

Witness: L1 12712 (hof, nameedit, L x15, rzx x52).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 12,712 calls (`stage1/rzx/r335610` 1,133, `stage1/rzx/r077928` 1,061, `stage1/rzx/r319697` 847 and 66 more) |
| Called from | `UpdateGremlins` |
| Calls | `Random` |
| Reads | `$AB67`-`$AB8C` (`Gremlins+4`); `$FD23`-`$FDB9` (`work space $FD23+`) |
| Writes | `$AB64`-`$AB88` (`Gremlins+1`); `$FD23`-`$FDB9` (`work space $FD23+`) |

### `GremlinMove` (`$AC4D`)

**A step in a random direction, inside the play area, onto a free cell or between cells**

New X = X + dX below 29, new Y = Y + dY below 17 (GremlinSteps). On a cell (both even): the cell's address to +4/+5; an empty cell, a cell `$40` or a mine `$41`: go; a mirror (`$01-$10`): go and stand, turns = `$8E33` AND 7; anything else: no step. Between cells: +5 = 0 and the four characters under the new place (CharMap `$E000` + 32 x (Y + 1) + X + 1) must each be below `$31` or `$74-$7B`, else no step.

Evidence: 97 827 runs (54 RZX segments).

Witness: L1 121430 (hof, nameedit, L x18, rzx x54).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 121,430 calls (`docs/integrate/rec/nameedit` 8,965, `stage2/rec/hof` 8,965, `stage1/rzx/r340213` 6,922 and 71 more) |
| Called from | `UpdateGremlins` |
| Calls | `Random` |
| Reads | `$8E33` (`RandomSeed+1`); `$AB65`-`$AB9E` (`Gremlins+2`, `GremlinNewX`, `GremlinNewY`, `GremlinCount` and 2 more); `$E022`-`$E25D` (`work space $E022+`); `$FD23`-`$FDB9` (`work space $FD23+`) |
| Writes | `$AB64`-`$AB94` (`Gremlins+1`, `GremlinNewX`, `GremlinNewY`) |

### `DrawGremlin` (`$ACFF`)

**Mark the gremlin's 2 x 2 characters for redraw and OR its frame into the pixel buffer**

DrawMarks `$E300` + 32 x (Y + 1) + X + 1 (and the three next to it) = 2; the frame (`$AAE3` + GremlinPhase) ORed into PixelBuffer `$E900` + 256 x (Y + 1) + X + 1, 16 rows of 2 bytes. The +1 is the play area's border character.

Evidence: 109 267 runs.

Witness: L1 134460 (hof, nameedit, L x18, rzx x54).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 134,460 calls (`docs/integrate/rec/nameedit` 9,276, `stage2/rec/hof` 9,276, `stage1/rzx/r340213` 6,930 and 71 more) |
| Called from | `UpdateGremlins`, `GremlinAppear` (tail) |
| Reads | `$AAE3`-`$AB96` (`GremlinFrames`, `Gremlins`, `GremlinNewX`, `GremlinNewY` and 2 more); `$EA01`-`$FBFE` (`work space $EA01+`) |
| Writes | `$E321`-`$E55E` (`work space $E321+`); `$EA01`-`$FBFE` (`work space $EA01+`) |

## hiscore

`src/game/hiscore.asm`

### `HallOfFame` (`$9BC0`)

**After a game: rank the score, take a name for the hall of fame, draw the options screen**

Called by the title loop `$840C` after each game (c1, c1g, controls, energy-out, gameover, hof, kempston, menu, mine, overload, rzx-344752). Interrupts off, the sound flags cleared, `$A103` = `$FF` (the interrupt's title mode). After practice (`$8407`): only the options screen (`DrawMenuScreen` `$9ED8`) and the COMPUTER line `$A199`.

Else the score's six digits (spaces as 0) go to ScoreCopy `$9B84`, `RankScore` `$9E1F` gives the place 1-7. 7: just the options screen. Else the lower records move down one (scores 9 bytes a record from `$9FEB`, names 8 bytes from `$A022`, the last dropped), the score is written into its record, the name cleared to five spaces, the rows renumbered (`RenumberHallOfFame` `$9E00`), the screen drawn and wiped in (`$8C95`), a tone (`$A843`, `$3250`), the COMPUTER line "HIGH DEFLEKTOR RATING ... PLEASE ENTER YOUR NAME" (`$A28E`, its `$A2A4` patched to `$FE`).

The name: up to five letters at column `$12` of the hall of fame's row 8 + rank, a blinking diamond (`$9FE3`, attribute `$3A`) every 70 polls at the next place. The letters A-Z (`ReadLetterKey` `$9E5A`), SPACE, DELETE (0) one back, ENTER ends: the screen redrawn from the buffer (`$9ED8`, `$8B9B`), a tone (`$465A`) and six delays (`$8908`).

Recordings: `hof` (place 6, the name AGENT in five letters, frames 17 051-17 151, then ENTER and CopyFullScreen `$9DD6`) and `rzx-344752` (one letter, R, then ENTER). The full name (`$9D7E`) ran in `hof`. `nameedit` (the same start as `hof`; A, G, DELETE, SPACE, E, N, T, X, ENTER) runs DELETE (`$9D15`) and SPACE (`$9D5A`) once each and the full name's refusal of X (`$9D7E`): the name A ENT.

Witness: L1 15 (c1, c1g, controls, energy-out, gameover, hof, kempston, menu, mine, nameedit, overload, rzx344752).

| | |
| --- | --- |
| Runs (c1g: the c1 recording's game window, from the jump to `$8382` (frame 15752 T 33930): the menu and play) | 1 call, 549 t-states own (0.00 %) |
| Runs (the other recordings) | 14 calls (`stage1/controls` 3, `stage1/menu` 2, `docs/integrate/rec/nameedit` 1 and 8 more) |
| Called from | `TitleLoop` |
| Calls | `Delay`, `CopyFullScreen`, `WipeInScreen`, `PutGlyph`, `EraseNameCursor`, `RenumberHallOfFame`, `RankScore`, `ReadLetterKey`, `TestKey`, `DrawMenuScreen`, `TwoTone` |
| Reads | `$8407` (`PracticeFlag`); `$9B3E`-`$9B43` (`ScoreDigits`); `$9B76`-`$9B89` (`NameEntryVars`, `NameColumn`, `Rank`, `RecordsToMove` and 8 more); `$9FEC`-`$A050` (`HallOfFameScores+1`, `HallOfFameNames`) |
| Writes | `$5932`-`$5933` (screen); `$59D2`-`$59D7` (screen); `$9B76`-`$9B89` (`NameEntryVars`, `NameColumn`, `Rank`, `RecordsToMove` and 8 more); `$9FEE`-`$A051` (`HallOfFameScores+3`, `HallOfFameNames`); `$A103`-`$A10F` (`MenuScroller`, `MessageNumber`, `MessageGlyph`, `MessageState` and 1 more); `$A2A4` (`RatingPause`); 1 more ranges |
| Ports in | `$00FE` |

### `PutGlyph` (`$9DE8`)

**Copy an 8-byte glyph from HL to the screen at NameScreen**

Eight rows down from the address in `$9B7C`. Used by the name entry and by the title's options code (`$A7A0`, `$A7F9`, `$A82F`).

Witness: L1 107 (c1, c1g, controls, energy, energy-out, hof, kempston, menu, nameedit, practice, rzx344752).

| | |
| --- | --- |
| Runs (c1g: the c1 recording's game window, from the jump to `$8382` (frame 15752 T 33930): the menu and play) | 10 calls, 3,406 t-states own (0.00 %) |
| Runs (the other recordings) | 97 calls (`docs/integrate/rec/nameedit` 34, `stage2/rec/hof` 24, `stage1/controls` 12 and 7 more) |
| Called from | `HallOfFame`, `EraseNameCursor` (tail), `OptionsMenu` |
| Reads | `$9B7C`-`$9B7D` (`NameScreen`); `$9FE3`-`$9FEA` (`NameCursorGlyph`); `$D200`-`$D207` (`Font`); `$D308`-`$D30F` (`Font+264`); `$D328`-`$D33F` (`Font+296`); `$D370`-`$D377` (`Font+368`); 1 more ranges |
| Writes | `$4802`-`$5002` (screen); `$5102` (screen); `$5202` (screen); `$5302` (screen); `$5402` (screen); `$5502` (screen); 2 more ranges |

### `EraseNameCursor` (`$9DF5`)

**Clear the name cursor: attribute `$38` and a space**

From the DELETE (`$9D15`) and SPACE (`$9D5A`) paths: run twice in `nameedit`, once each.

Witness: L1 2 (nameedit).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 2 calls (`docs/integrate/rec/nameedit` 2) |
| Called from | `HallOfFame` |
| Calls | `PutGlyph` (tail) |
| Reads | `$9B7E`-`$9B7F` (`NameAttr`) |
| Writes | `$59D3`-`$59D4` (screen) |

### `RenumberHallOfFame` (`$9E00`)

**Set the rows of the hall of fame's records to 9-14**

The third byte (the row) of the six names' records (`$A024`, 8 bytes apart) and of the six scores' (`$9FED`, 9 bytes apart): 9, 10, ... 14, after records were moved.

Witness: L1 3 (hof, nameedit, rzx344752).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 3 calls (`docs/integrate/rec/nameedit` 1, `stage1/rzx/r344752` 1, `stage2/rec/hof` 1) |
| Called from | `HallOfFame` |
| Writes | `$9FED`-`$A04C` (`HallOfFameScores+2`, `HallOfFameNames`) |

### `RankScore` (`$9E1F`)

**The place of ScoreCopy in the hall of fame: 1-6, or 7 when it is too low**

Compares the six digits of ScoreCopy `$9B84` with the scores from the last (`$A01B`) upwards; the place goes down from 7 while the score is greater than the record's; equal does not pass. Returns the place in A and Rank `$9B78`.

Witness: L1 15 (c1, c1g, controls, energy-out, gameover, hof, kempston, menu, mine, nameedit, overload, rzx344752).

| | |
| --- | --- |
| Runs (c1g: the c1 recording's game window, from the jump to `$8382` (frame 15752 T 33930): the menu and play) | 1 call, 229 t-states own (0.00 %) |
| Runs (the other recordings) | 14 calls (`stage1/controls` 3, `stage1/menu` 2, `stage1/rzx/r344752` 1 and 8 more) |
| Called from | `HallOfFame` |
| Reads | `$9B78`-`$9B85` (`Rank`, `RecordsToMove`, `NamePointer`, `NameScreen` and 6 more); `$9FEE`-`$A01C` (`HallOfFameScores+3`) |
| Writes | `$9B78` (`Rank`) |

### `ReadLetterKey` (`$9E5A`)

**Which letter key is newly pressed: carry and A = 1-26, or no carry**

Tests the 26 key codes of `LetterKeys` `$9EBD` with `TestKey` `$9EA2`. A held key: carry only when it differs from LastKey `$9B81`; KeyHeld `$9B80` = 1 while any letter is held, 0 when none.

Witness: L1 4639 (hof, nameedit, rzx344752).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 4,639 calls (`docs/integrate/rec/nameedit` 2,460, `stage2/rec/hof` 1,973, `stage1/rzx/r344752` 206) |
| Called from | `HallOfFame` |
| Calls | `TestKey` |
| Reads | `$9B81`-`$9B83` (`LastKey`, `BlinkTimer`, `LetterIndex`); `$9EBD`-`$9ED7` (`LetterKeys`) |
| Writes | `$9B80`-`$9B83` (`KeyHeld`, `LastKey`, `BlinkTimer`, `LetterIndex`) |

### `TestKey` (`$9EA2`)

**Test one key: A = 8 x (4 - bit) + half-row, NC when it is held**

The half-row 0-7 is `$7FFE`, `$BFFE`, `$DFFE`, `$EFFE`, `$F7FE`, `$FBFE`, `$FDFE`, `$FEFE`; the high three bits count the key from the outer end of the half-row (bit 4 first). So `$21` is ENTER, `$20` SPACE, `$23` 0 (DELETE).

Witness: L1 109958 (hof, nameedit, rzx344752).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 109,958 calls (`docs/integrate/rec/nameedit` 60,811, `stage2/rec/hof` 43,572, `stage1/rzx/r344752` 5,575) |
| Called from | `HallOfFame`, `ReadLetterKey` |
| Ports in | `$7FFE`, `$BFFE`, `$DFFE`, `$EFFE`, `$FBFE`, `$FDFE`, `$FEFE` |

## interrupt

`src/game/interrupt.asm`

### `SetupInterrupts` (`$A2FA`)

**IM 2: JP InterruptHandler at `$FDFD`, the vector table `$FE00-$FF00` of `$FD`, I = `$FE`; the COMPUTER line empty**

Called once, by the entry's new game `$8408` (at `$8409`, interrupts off). Writes `$C3` to `$FDFD` and InterruptHandler's address to `$FDFE`; MessageText = BlankMessage (pending), MessagePointer = 0; 257 bytes of `$FD` from `$FE00` (B = 0 gives 256, then one more at `$FF00`), I = `$FE`, IM 2. The interrupt is enabled later by the callers (`EI` at `$843B`).

Evidence: ran once in `c1g` (frame 15 752, the entry); the other recordings start from snapshots taken after it.

Witness: L1 2 (c1, c1g).

| | |
| --- | --- |
| Runs (c1g: the c1 recording's game window, from the jump to `$8382` (frame 15752 T 33930): the menu and play) | 1 call, 6,810 t-states own (0.00 %) |
| Runs (the other recordings) | 1 call (`stage1/c1` 1) |
| Called from | `Start` |
| Writes | `$A10E`-`$A111` (`MessageText`, `MessagePointer`); `$FDFD`-`$FF00` (`work space $FDFD+`) |

### `RestoreIm1` (`$A323`)

**I = `$3E` and IM 1: back to the ROM's interrupt (no caller)**

`LD A,$3E; IM 1; LD I,A; RET`. No instruction in the image calls or jumps here and no recording ran it (known only from the code): the way back to the ROM's interrupt mode, perhaps for a version that returned to BASIC.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `InterruptHandler` (`$A32A`)

**Every frame: EnergyTick, FrameCounter, the COMPUTER line (scroll or blink), then the beeper effect**

Entered through `JP $A32A` at `$FDFD` (the IM 2 vector). Saves HL, DE, BC, AF (not IX, IY or the alternate set). With MenuScroller `$A103` set it goes to MenuScrollerTick `$A459`. Else:

1. EnergyTick `$A506` + 1 (DrainEnergy `$A613` compares it with the level's rate) and FrameCounter `$837F` + 1.

2. A new message (MessageText's high byte not 0): if a static message is in its blank phase (MessageState `$E6-$EF`) it is drawn at once (state `$F0`) and the new one waits a frame; else MessagePointer = MessageText, the high byte cleared; a text that starts with `$FE` is static (state `$FE`: the next frame clears the line and the blink starts at `$E6`), any other starts scrolling at its first character.

3. No new message: a static message counts its blink (`$E6-$EF` blank, `$F0` draw the 14 characters at `$50E1`, `$FF` clear the line `$50E0-$50EF` and back to `$E6`); a scrolling one shifts the 5 pixel rows `$50E0-$50EF` (row 23, columns 0-15, scan lines 0-4) a pixel left with the next column of MessageGlyph coming in at the right, and every 8 pixels loads the next character (`$FF`: the word after it is where the text goes on; jumping back to BlankMessage clears MessageNumber).

4. InterruptExit `$A450`: PlaySoundFlags `$A8A7`, the registers back, `EI`, `RET`.

The POKE file's "Infinite lives" 41784,0 writes `NOP` over the `INC A` at `$A338`: EnergyTick never moves, so the energy never drains.

Evidence: 381 862 entries over all recordings, one a frame (`c1g` 4473 in 4808 frames: the load's frames before the entry have none; `rzx-004833` 7019 in 7019 frames); 3377 T an entry on average in `c1g` (WALKTHROUGH 1).

Witness: L1 487506 (c1, c1g, cheat, controls, corner, ending, energy, energy-out, gameover, hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x60).

| | |
| --- | --- |
| Runs (c1g: the c1 recording's game window, from the jump to `$8382` (frame 15752 T 33930): the menu and play) | 4,473 calls, 10,019,342 t-states own (2.98 %) |
| Runs (the other recordings) | 479,633 calls (`stage2/rec/energy-out` 18,370, `stage1/energy` 18,113, `docs/integrate/rec/nameedit` 17,189 and 90 more) |
| Calls | `InterruptExit` (tail), `MenuScrollerTick` (tail) |
| Reads | `$50E0`-`$50EF` (screen); `$51A5`-`$51B9` (screen); `$51E0`-`$51EF` (screen); `$52A5`-`$52B9` (screen); `$52E0`-`$52EF` (screen); `$53A5`-`$53B9` (screen); 12 more ranges |
| Writes | `$50E0`-`$50EF` (screen); `$51A5`-`$51B9` (screen); `$51E0`-`$51EF` (screen); `$52A5`-`$52B9` (screen); `$52E0`-`$52EF` (screen); `$53A5`-`$53B9` (screen); 10 more ranges |

### `InterruptExit` (`$A450`)

**The common end of the handler: the beeper effect of SoundFlags, the registers back, EI, RET**

Reached by the fall from the line's scroll and by the jumps of every other path. PlaySoundFlags `$A8A7` runs with the interrupt still off, so a long effect delays the main code (it never spans a frame: the longest flag effect played, ChargeWarble `$81E8` for bit 4, takes 0.41 frame; `$81D4`'s bit 0 is never set).

Witness: L1 487506 (c1, c1g, cheat, controls, corner, ending, energy, energy-out, gameover, hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x60).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 505 calls (`stage2/rec/ending` 267, `stage1/rzx/r344752` 238) |
| Called from | `InterruptHandler` (tail), `MenuScrollerTick` (tail) |
| Calls | `PlaySoundFlags` |

### `MenuScrollerTick` (`$A459`)

**The menu's line: row 21, columns 5-25 scrolled a pixel a frame; bytes `$82-$FE` in the text are pauses**

From InterruptHandler when MenuScroller `$A103` is set. A new message is taken (MessagePointer = MessageText, the high byte cleared) and the line `$51A5` (5 pixel rows of 21 bytes, scan lines 1-5) cleared. Then each frame: if the next text byte is `$81` or more it is a pause (MenuPause), else the 21 bytes `$51A5-$51B9` of the 5 rows are shifted a pixel left with MessageGlyph's next column coming in (MenuScrollPixel), and every 8 pixels the next character is loaded (`$FF`: go on at the next word).

A pause byte counts down in the text itself, a frame a step: `$FE` to `$E6` (24 frames) the line stands; `$E5` to `$82` (100 frames) its attributes (`$5AA5`, 21 bytes) flash, bit 4 of the count choosing `$3F` (white on white, hidden) or `$38` (black on white), 16 frames each; at `$81` the byte is set back to `$FE` and the text goes on. The callers write `$FE` again before they set the text (`$A769`, `$9CAE`), since an interrupted count stays in the text.

No tick is counted on this path (EnergyTick, FrameCounter).

Evidence: 2490 entries (`c1g`, `controls`, `energy`, `kempston`, `menu`, `rzx-344752`); the pause (`$A4AA`) only in `controls`: 126 frames, the flash 101, the end of the pause once.

Witness: L1 3417 (c1, c1g, controls, energy, energy-out, hof, kempston, menu, nameedit, practice, rzx344752).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 28 calls (`stage1/rzx/r344752` 28) |
| Called from | `InterruptHandler` (tail) |
| Calls | `InterruptExit` (tail) |
| Reads | `$51A5`-`$51B9` (screen); `$52A5`-`$52B9` (screen); `$53A5`-`$53B9` (screen); `$54A5`-`$54B9` (screen); `$55A5`-`$55B9` (screen); `$A107`-`$A111` (`MessageGlyph+2`, `MessageState`, `MessageText`, `MessagePointer`); 2 more ranges |
| Writes | `$51A5`-`$51B9` (screen); `$52A5`-`$52B9` (screen); `$53A5`-`$53B9` (screen); `$54A5`-`$54B9` (screen); `$55A5`-`$55B9` (screen); `$A105`-`$A111` (`MessageGlyph`, `MessageState`, `MessageText`, `MessagePointer`) |

## ending

`src/game/ending.asm`

### `EndingScreen` (`$A8CE`)

**The ending: CONGRATULATIONS ..., the plug and the kettle joined by the cable, the tea, PRESS ANY KEY**

Called by `$87F3` (at `$8893`) after level 60, the buffers cleared (`$8885`). Prints EndingText (`$8E3A`) into the buffers, shows them (`$8B9B`), waits 16 x `$8908`, draws EndingPlug at row 13 column 4 (2 x 16) and EndingKettle at row 12 scan line 4, column 25 (3 x 20) straight on the screen, waits 12, plays `$81F2`, draws the cable (two pixel rows of 19 bytes `$FF`: `$4FA6` and `$48C6`, row 13 line 7 and row 14 line 0, columns 6-24), waits 4, then sets the attributes of rows 17-18 to 7 and of row 23 columns 2-29 to 4: the lines printed in attribute 0 (THE TEA WILL BE READY IN FIVE MINUTES!, PRESS ANY KEY) appear.

The joke: the circuit is a mains cable from the plug to an electric kettle.

Evidence: ran once, `rzx-344752` (the RZX run's ending; screen 750).

Witness: L1 2 (ending, rzx344752).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 2 calls (`stage1/rzx/r344752` 1, `stage2/rec/ending` 1) |
| Called from | `LevelCompletePause` |
| Calls | `Delay`, `CopyFullScreen`, `PrintFull`, `PlaySound` |
| Reads | `$AA87`-`$AAE2` (`EndingPlug`, `EndingKettle`) |
| Writes | `$48A4`-`$48A5` (screen); `$48B9`-`$48DB` (screen); `$49A4`-`$49A5` (screen); `$49B9`-`$49C5` (screen); `$49D9`-`$49DB` (screen); `$4AA4`-`$4AA5` (screen); 18 more ranges |


## The tape: line 0 and its code (`src/tape/basic.json`)

Deflektor, Gremlin Graphics 1987: TZX block 1, the BASIC "DEFLEKTOR" (384 bytes at PROG `$5CCB`, LINE 0): line 0 and
its code at `$5D05`, and the loader's first stage `$5D17-$5E4A`, which runs at `$B626`. Its entries are
`src/tape/<module>.asm`, written from `src/tape/basic.ann` by `kit/mkgame.py --part src/tape/basic.json`; the
recordings: `work/stage1/c1g` (c1g: the c1 recording's game window, from the jump to `$8382` (frame 15752 T 33930):
the menu and play), and `work/stage1/c1` (`$5CCB`-`$5D16`). This section is the segment `$5CCB-$5D16` of the image.

| Module | Entries | Code entries |
| --- | --- | --- |
| [`basic`](#the-tape-line-0-and-its-code-basic) | `$5CCB`-`$5D16` | 1 of 3 |

### The tape: line 0 and its code: basic

`src/tape/basic.asm`

#### `BasicCode` (`$5D05`)

**USR's code: copy the loader's first stage (`$134` bytes from `$5D17`) to `$B626` and run it**

Entered by USR with BC = `$5D05`, the routine's own address: HL = BC + `$12` = `$5D17`, wherever the program was loaded. SP = `$5C00`, the stack below the main block's load address (the stack stays there to the end of the load). LDIR `$134` bytes to `$B626-$B759` and `JP $B65B` (Loader1Start). Interrupts are still on: Loader1Start turns them off after clearing the screen.

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1 call (`stage1/c1` 1) |


## The tape: the loader's first stage (`src/tape/basic.json`)

Deflektor, Gremlin Graphics 1987: TZX block 1, the BASIC "DEFLEKTOR" (384 bytes at PROG `$5CCB`, LINE 0): line 0 and
its code at `$5D05`, and the loader's first stage `$5D17-$5E4A`, which runs at `$B626`. Its entries are
`src/tape/<module>.asm`, written from `src/tape/basic.ann` by `kit/mkgame.py --part src/tape/basic.json`; the
recordings: `work/stage1/c1g` (c1g: the c1 recording's game window, from the jump to `$8382` (frame 15752 T 33930):
the menu and play), and `work/stage1/c1` (`$B626`-`$B759`). This section is the segment `$5D17-$5E4A` of the image,
run at `$B626-$B759`.

| Module | Entries | Code entries |
| --- | --- | --- |
| [`loader1`](#the-tape-the-loaders-first-stage-loader1) | `$B626`-`$B759` | 8 of 10 |

### The tape: the loader's first stage: loader1

`src/tape/loader1.asm`

#### `Loader1Start` (`$B65B`)

**The first stage: clear the screen, copy the ROM font to `$B326`, find the pilot, load stage 2's first piece**

From BasicCode's `JP $B65B`.

1. The attributes `$5800-$5AFF` filled with ClsAttr (0) and the pixels `$4000-$57FF` with 0, both by LDDR from the top (BC = 0 after the first LDDR gives the 0 for the second).

2. LDIR the 768 bytes of RomFont `$3D00` to FontPtr's `$B326`: characters 32-127 for PrintGlyph. The fourth load replaces characters 32-90 with Deflektor's own.

3. DI; FindPilot (no pilot within its time: `JP $0000`); H = 0, the checksum; LoadBlock IX = `$B75A`, DE = `$010F`, stage 2's first piece; `JP $B856` (LoadRest, in that piece).

Witness: L1 2 (c1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1 call (`stage1/c1` 1) |
| Calls | `FindPilot`, `LoadBlock` |

#### `FindPilot` (`$B693`)

**Find the turbo block's pilot and its sync: NC when no edge comes within 2000 tries**

The border to BorderColour with MIC set (`OR $08`); C = the port `$FE` level now (the edge waits compare bit 6 with it).

1. Up to 2000 EdgeWait calls for a first edge; none: `RET` with NC (HL = 0).

2. Then pilot pairs (EdgePair from B = `$9C`) whose count must pass `$C6` (a pair of 2127 T pulses gives about 60): 256 - H in a row (H = the high byte of the tries left, so 249 in c1), any short pair starts again.

3. The sync: single edges from B = `$C9` while the count reaches `$D4` (the rest of the pilot); the first shorter one is the first sync pulse (693 T), and `JP $B70E` waits for the second's edge. Returns with carry set.

The same plan as the ROM's LD-LEADER and LD-SYNC with its own constants. c1 counted 249 pilot pairs, then 4337 pilot edges to the sync.

Witness: L1 2 (c1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1 call (`stage1/c1` 1) |
| Called from | `Loader1Start` |
| Calls | `EdgePair`, `EdgeWait` (tail) |
| Ports in | `$00FE` |
| Ports out | `$00FE` |

#### `ReadByte` (`$B6D4`)

**Read one byte into L: 8 pairs MSB first and an invert flag, then the padding pairs; NC on a timeout**

DE is kept. D = `$FC`, E = 9 pairs. Each pair is EdgePair from the B the caller or the last pair left (B = `$B0` after each); a count above `$CB` is a 1. Each bit goes into L by the next pass's `RL L`, so after 9 passes L holds bits 1-8 and the carry the ninth, the invert flag: `SBC A,A; XOR L` complements L when the flag is 1. D counts the 0 pairs from -4.

Then D - 1 = zeros - 5 padding pairs, never tested (FILL bits). So a byte is 9 + zeros - 5 pairs; with a 1 as long as two 0s, every byte lasts 13 short pairs. The encoder writes the form with fewer ones (tools/tapesim.py `byte_bits`), so zeros is 5 to 9 and the padding 0 to 4.

Out: L = the byte, carry set; NC (and B wrapped) on a timeout. Called by LoadBlock for each byte and for the checksum.

Witness: L1 82906 (c1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 41,453 calls (`stage1/c1` 41,453) |
| Called from | `LoadBlock` |
| Calls | `EdgePair` |

#### `PadPairs` (`$B6FD`)

**Stage 2's hook padding: read pairs until L's marker bit leaves bit 7, then L = `$FF`**

Called by stage 2's HookWork (`$B784`). L holds a marker bit (2 at the hook's start) that every pair the hook reads moves up: here each pair shifts a 1 in with `RL L` until the marker falls out into the carry. So the hook always reads 7 pairs in all (the countdown's and the script's included), 6 long and the last short (tools/tapesim.py gives 0 when bit 7 of L is set): the time of 13 short pairs, one byte's.

Out: L = `$FF` and carry set (stage 2 then gives that L to ByteHook as if it were a byte: XORed into H and counted); NC on a timeout.

Witness: L1 60788 (c1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 4,481 calls (`stage1/c1` 4,481) |
| Calls | `EdgePair` |

#### `EdgePair` (`$B70A`)

**Wait for two edges (one pulse pair), counting in B; NC on a timeout**

EdgeWait twice (the second by falling into it). Called by FindPilot, ReadByte, PadPairs, LoadBlock and stage 2.

Witness: L1 914788 (c1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 457,394 calls (`stage1/c1` 457,394) |
| Called from | `FindPilot`, `ReadByte`, `PadPairs`, `LoadBlock` |
| Calls | `EdgeWait` (falls into) |

#### `EdgeWait` (`$B70E`)

**Wait 350 T, then for the next edge, counting 56 T passes in B: carry = an edge, NC = B wrapped**

A delay of 25 x 14 T, then EdgeNoDelay `$B714` (stage 2 calls it directly): `AND A` (carry clear) and the loop. A pass: `INC B` (a wrap to 0 is the timeout: `RET Z` with NC), port `$FE` read with A = 0, XOR C, `AND $40` (EAR). An edge: C = NOT C (the new level), carry set.

The pass is the ROM's LD-SAMPLE length (56 T); a never-taken `RET C` and a `NOP` stand where the ROM tests SPACE and changes the border, so the screen keeps its border and BREAK does nothing.

Witness: L1 1857012 (c1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 928,506 calls (`stage1/c1` 928,506) |
| Called from | `FindPilot` (tail), `EdgePair` (falls into) |
| Ports in | `$00FE` |

#### `LoadBlock` (`$B727`)

**Load DE bytes to IX: one lead pair, the bytes (ByteHook after each), the checksum byte against H, then on into ByteHook**

IX = the address, DE = the length; H = the running checksum. A lead pair (EdgePair from B = `$B0`; NC: `JP $0000`). For each byte: ReadByte (NC: reset), store L at (IX), IX + 1, B + 3 (the time of this code before the next pair), ByteHook. Then ReadByte for the checksum byte and `JP NZ,$0000` unless it equals H. There is no RET: the code runs on into ByteHook, which XORs the checksum byte into H (H = 0, the next load's start), counts it in HookCount like a data byte (so the hooks keep their period across the loads) and returns to LoadBlock's caller. IX is left past the block.

Called 8 times: by Loader1Start (`$B75A`, `$10F`) and by stage 2 (LoadRest: `$B869`, `$74` and `$B8DD`, `$302`; LoadFiles: `$B326`, `$01D8`; `$998E`, `$1998`; `$C000`, `$4000`; `$5C00`, `$4000`; `$9C00`, `$01F0`).

Witness: L1 16 (c1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 8 calls (`stage1/c1` 8) |
| Called from | `Loader1Start` |
| Calls | `ReadByte`, `EdgePair`, `ByteHook` (falls into) |

#### `ByteHook` (`$B752`)

**After each byte: H = H XOR L; once stage 2 has armed it, every 8th call runs stage 2's work**

The checksum first. Then A = HookCount - 1: negative (HookCount 0, before stage 2 arms it) returns at once (`RET M`). Otherwise the routine runs on past this stage's end into Stage2 `$B75A`, which stores the count and returns until it is 0, then does the countdown and the script, reads the hook's pairs, and comes back here with L = `$FF` (counted and XORed like a byte; work/ann/04-loader.md).

Called by LoadBlock after each byte, entered by LoadBlock's end after the checksum byte, and jumped to by stage 2 at the end of its work (L = `$FF`).

c1: 5882 hooks ran (tools/tapesim.py run, work/ann/04-loader/hooks.py): after 8 bytes of the second load, then every 7 bytes and the hook's own count (6 data bytes and the last load's checksum byte at the start of the third to eighth loads).

Witness: L1 94670 (c1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 47,335 calls (`stage1/c1` 47,335) |
| Called from | `LoadBlock` (falls into) |


## The loader's second stage (`src/loader/stage2.json`)

Deflektor, Gremlin Graphics 1987: the loader's second stage, `$B75A-$BBDE`, loaded in three pieces by the first
(`$10F`, `$74` and `$302` bytes): the countdown, the loading screen's script engine and the rest of the load. Its
entries are `src/loader/<module>.asm`, written from `src/loader/stage2.ann` by `kit/mkgame.py --part
src/loader/stage2.json`; the recordings: `work/stage1/c1g` (c1g: the c1 recording's game window, from the jump to
`$8382` (frame 15752 T 33930): the menu and play), and `work/stage1/c1` (`$B75A`-`$BBDE`).

| Module | Entries | Code entries |
| --- | --- | --- |
| [`loader2`](#the-loaders-second-stage-loader2) | `$B75A`-`$B78D` | 1 of 1 |
| [`script`](#the-loaders-second-stage-script) | `$B78E`-`$B855` | 2 of 3 |
| [`countdown`](#the-loaders-second-stage-countdown) | `$B856`-`$B8DC` | 2 of 2 |
| [`control`](#the-loaders-second-stage-control) | `$B8DD`-`$BACB` | 20 of 20 |
| [`loads`](#the-loaders-second-stage-loads) | `$BACC`-`$BB4F` | 1 of 1 |
| [`cells`](#the-loaders-second-stage-cells) | `$BB50`-`$BBDE` | 1 of 5 |

### The loader's second stage: loader2

`src/loader/loader2.asm`

#### `HookWork` (`$B75A`)

**ByteHook's work: store the count; every 8th call the countdown tick, the script steps, the padding pairs**

Entered from ByteHook `$B752` in the first stage, which runs on into these bytes with A = HookCount - 1 and the return address in LoadBlock (`$B742`) on the stack.

1. HookCount = A; not 0: return. Else HookCount = 8, B = LoadFlags, L = 2 (the marker bit).

2. Bit 0 (the countdown): TickHooks - 1; at 0 CountdownTick, which returns A = 20 (`$14`) for TickHooks.

3. Bit 1 (the script): ScriptWait - 1; at 0 (ScriptWait stays 1, so the next hook steps again) ScriptStep, which ends at ByteHook by itself. Else ScriptWait is stored and the hook pads.

4. HookPad `$B784`: PadPairs (the rest of the 7 pairs), B = `$B2`, `JR C` to ByteHook with L = `$FF`: the hook XORs `$FF` into the checksum, counts itself in HookCount (8 - 1 = 7) and returns to LoadBlock. A timeout: `JP $0000`.

c1 (work/ann/04-loader/hooks.py): the first hook after 8 bytes of the second load, then one every 7 bytes and the hook (6 data bytes and the last load's checksum byte at the start of the third to eighth loads: LoadBlock runs on into ByteHook after the checksum); 5882 in all.

Witness: L1 47063 (c1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings run into, not called (`stage1/c1`) |
| Called from | `ScriptStep` (tail), `CodePause` (tail) |

### The loader's second stage: script

`src/loader/script.asm`

#### `ScriptStep` (`$B78E`)

**One script item (with EXX: the loader's registers kept), then one pulse pair; up to 6 a hook**

Entered by HookWork when ScriptWait runs out, and from its own end while the marker bit in L has not reached bit 7.

1. LoadFlags bit 3 (a picture is being drawn): PictureCell, one cell.

2. Else the byte at ScriptPtr (ScriptPtr + 1): `$04` ends the script (LoadFlags bit 1 cleared, then HookPad); below 32 ControlCode; else PrintChar `$B7B8`: PrintGlyph at PrintRow + PrintColumn in PrintAttr, then CursorRight `$B7CA` (PrintColumn + 1; past WindowRight back to WindowLeft and NextRow `$B7D8`: PrintRow + 32, past WindowBottom back to WindowTop).

3. ScriptPair `$B7F0`: EXX back, one long pair (EdgeNoDelay, EdgeWait), `SLA L`: the marker not yet in bit 7, another item. Else one short pair (EdgePair), L = `$FF`, B = `$B2`, `JP $B752` (ByteHook: the hook's end, as at HookPad).

c1 (work/ann/04-loader/reader.py): 8228 items in 1426 hooks. The two `$04` ends: SerialText's at 1.99 s and the script's (`$B325`) at 273.3 s, 17 s before the last load.

Witness: L1 8228 (c1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 8,228 calls (`stage1/c1` 8,228) |
| Called from | `ControlCode` (tail), `CodeDown` (tail) |
| Calls | `HookWork` (tail), `PrintGlyph`, `ControlCode`, `PictureCell` |

#### `PrintGlyph` (`$B812`)

**Print character A at the attribute address DE in attribute B (8 bytes from FontPtr + 8 x (A - 32))**

The glyph is FontPtr + 8 x A - 256 (character 32 is FontPtr's first). The attribute B goes to (DE), then DE becomes the cell's first pixel row (D x 8 AND `$78`: `$58` to `$40`, `$59` to `$48`, `$5A` to `$50`) and 8 bytes are copied down the cell. C is not used.

Called by ScriptStep (characters, from its registers in the other set) and CountdownTick (the digits).

Witness: L1 8435 (c1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 8,435 calls (`stage1/c1` 8,435) |
| Called from | `ScriptStep`, `CountdownTick` |

### The loader's second stage: countdown

`src/loader/countdown.asm`

#### `LoadRest` (`$B856`)

**Stage 2's entry: arm the hook, start the serial text, load the stage's last two pieces, then LoadFiles**

From Loader1Start's `JP $B856`, IX = `$B869` (just past the first piece) and H = the checksum.

1. HookCount = 8 (ByteHook works from now on); LoadFlags bit 1, the script (SerialText); LoadBlock `$74` bytes: `$B869-$B8DC`, the bytes this routine goes on with after the CALL.

2. LoadFlags bit 0, the countdown; LoadBlock `$302` bytes: `$B8DD-$BBDE`. `JP $BACC` (LoadFiles).

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1 call (`stage1/c1` 1) |
| Calls | `LoadFiles` (tail) |

#### `CountdownTick` (`$B87A`)

**One second less: Countdown - 1 in ASCII digits, shown at CountdownAt; past 000 the countdown stops**

Called by HookWork when TickHooks reaches 0 (EXX: the loader's HL, DE and B kept in the other set).

The three digits from the last: `SBC A,0` with the borrow, `DAA`, below `$30` a borrow on and `SET 4,A` ('0' - 1 gives '9'). A borrow out of the first digit (past 000): LoadFlags bit 0 off, the marker bit set at bit 7, one pair (CountdownWait). Else the digits are printed at CountdownAt (`$5AC1`) with CountdownPair's B (CountdownAttr `$57`), each after one long pair (EdgeNoDelay, EdgeWait; `RL L` with bit 0 of C, the level byte, as the carry: its value does not matter, the marker set at bit 4 leaves after 4 pairs whatever comes in): 4 pairs.

Out: A = 20 (TickHooks), B = LoadFlags. IgnoreCode `$B8DC` (the final `RET`) is also the control-code table's handler for the codes that do nothing.

c1: 294 ticks, 3475776 T apart (0.993 s), from 293 at 3.73 s to 000 at 293.70 s; the count never passed 000.

Witness: L1 294 (c1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 294 calls (`stage1/c1` 294) |
| Calls | `PrintGlyph` |

### The loader's second stage: control

`src/loader/control.asm`

#### `ControlCode` (`$B8DD`)

**A control code: `$0C`, `$0E` and `$1D` here, the others through ControlTable**

Called by ScriptStep with A = the code and the script pointer HL (the other register set) past it, in ScriptPtr as well.

TABFILL `$1D` n (`$B8FF`): the target column is n - 1, at most WindowRight. Until PrintColumn is the target, FillChar is printed and the code repeats (the pointer goes back to it); at the target, one more and n is taken: the print position ends at column n (through the next row when it was past it).

REPEAT `$0E` n (`$B914`): RepeatCount = n the first time (LoadFlags bit 2), then one FillChar a step, n in all (0: 256).

CLS `$0C` (`$B938`): the first time, the print position to the window's top left; then FillChar a step until the position is back there, then bit 2 off and a wait of 20 x 14 T. The window is filled with spaces, a cell a step (the script's 4677 `$0C` steps in c1).

A repeating step goes back one byte (ControlAgain `$B96B`), stores ScriptPtr, drops ScriptStep's return and prints FillChar through PrintChar.

The table: the handler from ControlTable + 2 x A, A = the byte at ScriptPtr, DE = ScriptPtr + 1, `JP (HL)`; it returns to ScriptStep.

Witness: L1 5843 (c1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 5,843 calls (`stage1/c1` 5,843) |
| Called from | `ScriptStep` |
| Calls | `ScriptStep` (tail), `CodePause`, `CodeReturn`, `CodePaper`, `CodeInk`, `CodeAt`, `CodeWindow`, `CodePicture` |

#### `CodePause` (`$B982`)

**`$03` n: wait n hooks before the next item (ScriptWait = n), ending this hook's steps**

Takes n, drops ScriptStep's return, EXX and HookPad: no more items this hook. HookWork steps again in the n-th hook from now. The script waits 23 times (c1), 50 to 250 hooks (about 2.5 to 12 s).

Witness: L1 23 (c1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings run into, not called (`stage1/c1`) |
| Called from | `ControlCode` |
| Calls | `HookWork` (tail) |

#### `CodeLeft` (`$B98E`)

**`$08`: the print position one column left; before WindowLeft, WindowRight of the row above**

No argument. Falls into CodeUp for the row.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `CodeUp` (`$B99C`)

**`$0B`: the print position one row up; above WindowTop, WindowBottom**

No argument. Not used by Deflektor's script.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `CodeRight` (`$B9B5`)

**`$09`: the print position one column right (CursorRight)**

No argument; drops ScriptStep's return and goes on at CursorRight `$B7CA`, so the step ends with ScriptPair as after a character.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `CodeReturn` (`$B9B9`)

**`$0D`: the print position to WindowLeft on the next row**

No argument. PrintColumn = WindowLeft, then CodeDown's NextRow. 86 times in c1.

Witness: L1 86 (c1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings run into, not called (`stage1/c1`) |
| Called from | `ControlCode` |

#### `CodeDown` (`$B9BF`)

**`$0A`: the print position one row down (NextRow), the column kept**

No argument.

Witness: L1 86 (c1).

| | |
| --- | --- |
| Runs | ran within another entry's routine (reached by a jump or by running on, its calls below), no runs of its own counted |
| Calls | `ScriptStep` (tail) |

#### `CodeGlyph` (`$B9C3`)

**`$19` c b1-b8: the 8 bytes of character c's glyph (32 or more) copied into the font**

Below 32 it returns at once and takes nothing (the next byte is read as an item). Else 8 bytes from the script to FontPtr + 8 x (c - 32); ScriptPtr past them. Not used by Deflektor's script (its glyphs are the fourth load).

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `CodeBorder` (`$B9DB`)

**`$1E` n: the border = n AND 7 (MIC set)**

Not used by Deflektor's script.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `CodePaper` (`$B9E9`)

**`$11` n: PrintAttr's paper = n (bits 3-5)**

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings run into, not called (`stage1/c1`) |
| Called from | `ControlCode` |
| Calls | `SetAttrBits` (tail) |

#### `CodeInk` (`$B9F0`)

**`$10` n: PrintAttr's ink = n (bits 0-2)**

Witness: L1 33 (c1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings run into, not called (`stage1/c1`) |
| Called from | `ControlCode` |
| Calls | `SetAttrBits` (tail) |

#### `CodeFlash` (`$B9F4`)

**`$12` n: PrintAttr's FLASH bit = bit 0 of n**

Not used by Deflektor's script.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `CodeBright` (`$B9F8`)

**`$13` n: PrintAttr's BRIGHT bit = bit 0 of n**

Not used by Deflektor's script. AttrFlag `$B9FA` (also CodeFlash's): A = `$FF` or 0 from bit 0 of n.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `SetAttrBits` (`$B9FC`)

**PrintAttr = (A AND C) OR (PrintAttr AND NOT C); take the argument**

C is the mask: `$07` ink, `$38` paper, `$80` flash, `$40` bright. IgnoreCode28 `$BA09` (its `RET`) is the table's handler of `$1C`.

Witness: L1 34 (c1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 34 calls (`stage1/c1` 34) |
| Called from | `CodePaper` (tail), `CodeInk` (tail) |

#### `CodeSwap` (`$BA0A`)

**`$18`: swap PrintAttr's ink and paper (FLASH and BRIGHT kept)**

No argument. Not used by Deflektor's script.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `CodeAt` (`$BA20`)

**`$16` row col: the print position inside the window (WindowLeft + col, WindowTop + 32 x row), clamped to it**

The column: WindowLeft + col, at most WindowRight (also on a carry). The row: WindowTop + 32 x row, at most WindowBottom. 24 times in c1.

Witness: L1 24 (c1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings run into, not called (`stage1/c1`) |
| Called from | `ControlCode` |
| Calls | `Times32` |

#### `Times32` (`$BA51`)

**HL = 32 x L (H = 0): a row's offset in the attributes**

Called by CodeAt, CodeWindow and CodePicture.

Witness: L1 45 (c1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 45 calls (`stage1/c1` 45) |
| Called from | `CodeAt`, `CodeWindow`, `CodePicture` |

#### `CodeFill` (`$BA59`)

**`$05` c: FillChar = c (the character CLS, REPEAT and TABFILL print)**

Not used by Deflektor's script: FillChar stays a space.

Witness: L1 0 ().

| | |
| --- | --- |
| Runs | not reached in the recordings |

#### `CodeWindow` (`$BA61`)

**`$1A` left right top bottom: the script's window; the print position to its top left**

The columns sorted; a right column of 32 or more makes the window 0-31. The rows sorted; a bottom row of 24 or more makes it 0-23. WindowLeft, WindowRight; WindowTop and WindowBottom as attribute addresses of column 0 (`$5800` + 32 x row); PrintRow = WindowTop, PrintColumn = WindowLeft.

Deflektor's script: `$1A` 1 30 10 20 (the text panel under the picture), and 0 31 0 21 before the last picture.

Witness: L1 2 (c1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings run into, not called (`stage1/c1`) |
| Called from | `ControlCode` |
| Calls | `Times32` |

#### `CodePicture` (`$BAA9`)

**`$0F` row col rows cols: draw a picture of rows x cols cells from the script, one cell a step**

The cells' screen place is absolute (not the window's): PictureAt = `$5800` + 32 x row + col, PictureRows = rows, PictureWidth = cols, RepeatCount = 0 (the column), LoadFlags bit 3: ScriptStep then calls PictureCell for every item until the picture is done. 17 pictures in Deflektor's script (the frame of 9 x 32 cells first).

Witness: L1 17 (c1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings run into, not called (`stage1/c1`) |
| Called from | `ControlCode` |
| Calls | `Times32` |

### The loader's second stage: loads

`src/loader/loads.asm`

#### `LoadFiles` (`$BACC`)

**Load the glyphs and the script, start the script, load the main block in three loads, move its tail, run it**

From LoadRest's `JP $BACC`.

1. LoadBlock GlyphsAddr, GlyphsLen (when not 0).

2. LoadFlags bit 1 (the script on again), ScriptWait = ScriptDelay (230 hooks), the print position to the window's top left, ScriptPtr = ScriptAddr; LoadBlock ScriptAddr, ScriptLen: the script runs while it loads.

3. MainLen of `$4000` or more: LoadBlock HighBuffer `$C000`, `$4000` (the block's last `$4000` bytes); MainLen - `$4000`.

4. IX = MainAddr (pushed: the return address at the end); LoadBlock `$4000` bytes while `$4000` or more are left; then the rest (when not 0). IX is now MainAddr + MainLen - `$4000`.

5. MainLen's high byte below 4: `RET` to MainAddr. Else `LDIR` (`$ED $B0`) and `RET` at MoveStub `$5B00`, HL = `$C000`, DE = IX (`$9DF0`), BC = `$4000`, `JP $5B00`: the copy runs from the printer buffer, outside the bytes it overwrites (this stage among them), and its `RET` goes to MainAddr `$5C00`.

The test in step 5 reads MainLen's high byte against 4, not `$40`: a main block of `$0400-$3FFF` bytes would still be "moved". Deflektor's `$81F0` takes the move.

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1 call (`stage1/c1` 1) |
| Called from | `LoadRest` (tail) |

### The loader's second stage: cells

`src/loader/cells.asm`

#### `PictureCell` (`$BB50`)

**Draw a picture's next cell from the script: an attribute and 8 pixel bytes; the picture's end clears LoadFlags bit 3**

Called by ScriptStep while LoadFlags bit 3 is set. The cell is PictureAt + RepeatCount (the column); the attribute byte goes there, the 8 pixel bytes down the cell (the attribute address turned into the pixel address as in PrintGlyph). ScriptPtr + 9. RepeatCount + 1; at PictureWidth, 0 again, PictureAt + 32 and PictureRows - 1; at 0 the picture is done.

c1: 474 cells (work/ann/04-loader/reader.py counted the calls).

Witness: L1 474 (c1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 474 calls (`stage1/c1` 474) |
| Called from | `ScriptStep` |


## The main block: the block's head (`src/head/head.json`)

Deflektor, Gremlin Graphics 1987: the main block's own code (496 bytes), decrypted: BlockHead `$5C00-$5C26`, the
chain `$7B52-$7CFF` and the mover `$FD00-$FD1A`; tools/cipher.py encrypts it with the game (src/head/keys.txt). Its
entries are `src/head/<module>.asm`, written from `src/head/head.ann` by `kit/mkgame.py --part src/head/head.json`;
the recordings: `work/stage1/c1g` (c1g: the c1 recording's game window, from the jump to `$8382` (frame 15752 T
33930): the menu and play), and `work/stage1/c1` (`$5C00`-`$5C26`). This section is the segment `$5C00-$5C26` of the
image.

| Module | Entries | Code entries |
| --- | --- | --- |
| [`head`](#the-main-block-the-blocks-head-head) | `$5C00`-`$5C26` | 1 of 1 |

### The main block: the block's head: head

`src/head/head.asm`

#### `BlockHead` (`$5C00`)

**Find the block's address with a stub at `$5B00`, move `$5C27-$DDEF` up to `$7B52` and run the chain there**

1. DI; `$E9E1` (POP HL; JP (HL)) at MoveStub `$5B00`; CALL it: HL = `$5C0A`, the address after the CALL.

2. HL + 29 = `$5C27`, the first encrypted byte; BC = `$81C9` (33225 bytes, `$5C27-$DDEF`); DE = `$7B52`, pushed: the RET's target.

3. The source below the target (it is): BlockMoveUp, HL and DE moved to the ends (+ BC - 1) and LDDR, so the overlap copies right. Else BlockMoveDown `$5C24`, LDIR (never taken on the tape).

4. RET to `$7B52`.

c1: one run, 33225 bytes moved.

Witness: L1 1 (c1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1 call (`stage1/c1` 1) |


## The main block: the decryption chain (`src/head/head.json`)

Deflektor, Gremlin Graphics 1987: the main block's own code (496 bytes), decrypted: BlockHead `$5C00-$5C26`, the
chain `$7B52-$7CFF` and the mover `$FD00-$FD1A`; tools/cipher.py encrypts it with the game (src/head/keys.txt). Its
entries are `src/head/<module>.asm`, written from `src/head/head.ann` by `kit/mkgame.py --part src/head/head.json`;
the recordings: `work/stage1/c1g` (c1g: the c1 recording's game window, from the jump to `$8382` (frame 15752 T
33930): the menu and play), and `work/stage1/c1` (`$7B52`-`$7CFF`). This section is the segment `$5C27-$5DD4` of the
image, run at `$7B52-$7CFF`.

| Module | Entries | Code entries |
| --- | --- | --- |
| [`chain`](#the-main-block-the-decryption-chain-chain) | `$7B52`-`$7CFF` | 15 of 25 |

### The main block: the decryption chain: chain

`src/head/chain.asm`

#### `ChainStart` (`$7B52`)

**Fill `$5B00-$7B51` with a generated stream (twice), then sum `$4000-$FFFF` into A and go to the first layer**

1. D = `$95`, E = 2 passes: from HL = `$5B00`, BC = `$2052` bytes: (HL) = D, D = 17 x D + L + 11. After the first pass HL = `$FD1B`, BC = `$02E5` (the space past the mover, `$FD1B-$FFFF`), the second pass.

2. A = D, HL = `$4000`: A + each byte to `$FFFF` (the carry out of HL ends the loop); `JR C` to ChainLayers.

The stream overwrites the BASIC, the system variables and the loader's stack area, so nothing of the BASIC loader survives.

Witness: L1 2 (c1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 1 call (`stage1/c1` 1) |

#### `XorLayer` (`$7B84`)

**Decrypt the B bytes after the CALL with key A and step C, add the key byte at the return address to A, write C there, return past it**

In: A the key, B the count (0 = 256), C the step; the return address on the stack.

Each byte: D = A, A = 17 x D + C, XOR (HL), stored; the decrypted byte is the next key. Then B restored from E, A + (return address), (return address) = C, `JP` to the return address + 1.

c1: 3642 bytes decrypted over 372 addresses (`$7BC0-$7D33`), up to 17 layers on one address.

Witness: L1 36 (c1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 18 calls (`stage1/c1` 18) |
| Called from | `ChainLayers`, `SumLayer1`, `Layers6`, `Layers10`, `Layers11`, `SumLayer2`, `Layers13`, `SumLayer3`, `Layers26`, `Layers27` |
| Calls | `ChainLayers`, `SumLayer1`, `Layers6`, `Layers11`, `Layers13`, `SumLayer3`, `Layers27` |

#### `ChainLayers` (`$7BB2`)

**The 30 layers in turn: each CALL is followed by its key byte, and the code after it exists only once the call returns**

1. `$CB` at ChainText (the plant), BC = `$46D9` with bit 7 of B set: the first XorLayer.

2. Then layer after layer, B and C changed by shifts and increments between the calls (EXX, OR E and the like are key bytes, not code: XorLayer writes C over them and jumps past). Sum layers SumLayer1 `$7BD2`, SumLayer2 `$7C15`, SumLayer3 `$7C54` sit inside the run, jumped over by `JR`.

3. After the 30th layer (at `$7CA2`): FinalSum.

c1: 30 layers, incoming A = 0 each (src/head/keys.txt).

Witness: L1 2 (c1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings run into, not called (`stage1/c1`) |
| Called from | `XorLayer` |
| Calls | `XorLayer` |

#### `SumLayer1` (`$7BD2`)

**A + B + the sum of every (C + 1)th byte from `$4000` to `$FFFF`, then the key byte at the return address, C written over it**

In: A the key, B, C the step - 1. HL = `$4000`, DE = C + 1; A + B, then A + (HL) until HL carries out past `$FFFF`; A + (return address), (return address) = C, `JP` past it.

SumLayer2 `$7C15` and SumLayer3 `$7C54` are the same code at other addresses (the chain's own bytes take part in the sums, so three copies give three different chains of keys).

Witness: L1 12 (c1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 6 calls (`stage1/c1` 6) |
| Called from | `XorLayer`, `Layers6`, `Layers9`, `Layers13`, `SumLayer3` |
| Calls | `XorLayer`, `Layers6`, `Layers9`, `Layers10`, `Layers13`, `Layers26` |

#### `Layers6` (`$7BF0`)

**The chain after key byte 5: the next layer's B and C, then its CALL**

Decrypted by an earlier layer, run once.

Witness: L1 2 (c1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings run into, not called (`stage1/c1`) |
| Called from | `XorLayer`, `SumLayer1` |
| Calls | `XorLayer`, `SumLayer1` |

#### `Layers9` (`$7C03`)

**The chain after key byte 8: the next layer's B and C, then its CALL**

Decrypted by an earlier layer, run once.

Witness: L1 2 (c1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings run into, not called (`stage1/c1`) |
| Called from | `SumLayer1` |
| Calls | `SumLayer1` |

#### `Layers10` (`$7C07`)

**The chain after key byte 9: the next layer's B and C, then its CALL**

Decrypted by an earlier layer, run once.

Witness: L1 2 (c1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings run into, not called (`stage1/c1`) |
| Called from | `SumLayer1` |
| Calls | `XorLayer` |

#### `Layers11` (`$7C0D`)

**The chain after key byte 10: the next layer's B and C, then its CALL**

Decrypted by an earlier layer, run once.

Witness: L1 2 (c1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings run into, not called (`stage1/c1`) |
| Called from | `XorLayer` |
| Calls | `XorLayer` |

#### `SumLayer2` (`$7C15`)

**A copy of SumLayer1**

The same eleven instructions as SumLayer1 `$7BD2`.

Witness: L1 6 (c1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 3 calls (`stage1/c1` 3) |
| Called from | `Layers13`, `Layers27` |
| Calls | `XorLayer`, `Layers13`, `Layers27`, `Layers30` |

#### `Layers13` (`$7C2E`)

**The chain after key byte 12: the next layer's B and C, then its CALL**

Decrypted by an earlier layer, run once.

Witness: L1 2 (c1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings run into, not called (`stage1/c1`) |
| Called from | `XorLayer`, `SumLayer1`, `SumLayer2` |
| Calls | `XorLayer`, `SumLayer1`, `SumLayer2` |

#### `SumLayer3` (`$7C54`)

**A copy of SumLayer1**

The same eleven instructions as SumLayer1 `$7BD2`.

Witness: L1 6 (c1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings 3 calls (`stage1/c1` 3) |
| Called from | `XorLayer`, `Layers30` |
| Calls | `XorLayer`, `SumLayer1` |

#### `Layers26` (`$7C88`)

**The chain after key byte 25: the next layer's B and C, then its CALL**

Decrypted by an earlier layer, run once.

Witness: L1 2 (c1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings run into, not called (`stage1/c1`) |
| Called from | `SumLayer1` |
| Calls | `XorLayer` |

#### `Layers27` (`$7C8C`)

**The chain after key byte 26: the next layer's B and C, then its CALL**

Decrypted by an earlier layer, run once.

Witness: L1 2 (c1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings run into, not called (`stage1/c1`) |
| Called from | `XorLayer`, `SumLayer2` |
| Calls | `XorLayer`, `SumLayer2` |

#### `Layers30` (`$7CA1`)

**The chain after key byte 29: the next layer's B and C, then its CALL**

Decrypted by an earlier layer, run once.

Witness: L1 2 (c1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings run into, not called (`stage1/c1`) |
| Called from | `SumLayer2` |
| Calls | `SumLayer3` |

#### `FinalSum` (`$7CA6`)

**Zero its own operand, sum `$4000-$FFFF` as 16-bit words into DE, decrypt `$7D00-$FD19` with it, jump to the last word + `$7A3D`**

1. DE = A (the 30th layer's A; E = 146 on the tape: the operand at `$7CA7` was 200 when it ran as part of the sums), A = 0 stored into that operand (`$7CA7`), so the sum below does not count it.

2. HL = `$4000`, BC = 1: DE + the word at HL, HL + 2, to `$FFFF`. On the tape DE = `$43FB` (src/head/keys.txt key16).

3. Final16 `$7CBE`: L = E, B = D (as H), C = `$29`; from `$7D00` in words: H = L, HL + BC, the low byte XOR L (L = the new byte), the high byte XOR H (B = the new byte), to `$FD1A`.

4. HL = the last word (`$82C3` on the tape) + `$7A3D` = `$FD00`; bit 7 of R set; `JP (HL)`: the mover.

c1: the 16-bit layer over 32794 bytes, 16397 words.

Witness: L1 2 (c1).

| | |
| --- | --- |
| Runs | not reached in the recordings |


## The main block: the mover (`src/head/head.json`)

Deflektor, Gremlin Graphics 1987: the main block's own code (496 bytes), decrypted: BlockHead `$5C00-$5C26`, the
chain `$7B52-$7CFF` and the mover `$FD00-$FD1A`; tools/cipher.py encrypts it with the game (src/head/keys.txt). Its
entries are `src/head/<module>.asm`, written from `src/head/head.ann` by `kit/mkgame.py --part src/head/head.json`;
the recordings: `work/stage1/c1g` (c1g: the c1 recording's game window, from the jump to `$8382` (frame 15752 T
33930): the menu and play), and `work/stage1/c1` (`$FD00`-`$FD1A`). This section is the segment `$5DD5-$5DEF` of the
image, run at `$FD00-$FD1A`.

| Module | Entries | Code entries |
| --- | --- | --- |
| [`mover`](#the-main-block-the-mover-mover) | `$FD00`-`$FD1A` | 1 of 1 |

### The main block: the mover: mover

`src/head/mover.asm`

#### `MoveGame` (`$FD00`)

**`$7D00-$FCFF` to `$6000-$DFFF`, BC = 0 to `$5C09`, SP = `$FFFF`, bit 7 of R cleared, JP GameEntry `$8382`**

The game's own copy of these bytes is the decrypted block; the mover's last word (the `JP $8382` operand) is the word FinalSum adds `$7A3D` to, so the jump to `$FD00` and the game's entry are one word.

c1: one run.

Witness: L1 3 (c1).

| | |
| --- | --- |
| Runs | not reached in `stage1/c1g`; in the other recordings run into, not called (`stage1/c1`) |
