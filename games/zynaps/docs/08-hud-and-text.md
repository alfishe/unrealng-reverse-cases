# 8. HUD and text

What this covers: the play panel and what draws each part of it, the gauges, the pod icon, the score and the lives,
the print routine and its codes, the two fonts, and the 28 messages with the pages they make.

The recordings it rests on:

| Recording | Made by | Frames | Used here for |
| --- | --- | ---: | --- |
| `work/zyB/w1` | `tools/podbot.py --plan 0,1,2,2,3,4` from `work/run/play-imm.szx` | 5986 | the panel at every fuel and speed state |
| `work/zyB/w2` | `tools/podbot.py --plan 3`, same snapshot | 7600 | the access trace of frames 6355-6460 (the panel restored at level 1's start) |
| `c1` | stage 1: the load and the title pages | | the title pages' L1 reads |

The text figures are drawn from the bytes alone: `build/game.bin` and the 48K ROM of unreal-ng (`data/rom/48.rom`),
printed by a model of the print routine (`tools/fig_text.py`).
The message texts as text are `src/res/text/messages.msg.txt`, the high-score table `src/res/text/hiscores.hsc.txt`
(`tools/res_text.py`).

## 8.1 The panel at a glance

The play screen has the score line at row 0 and the panel at rows 19-23.
The panel's pixels are a picture: RestorePanel `$A979` copies the bottom screen third and the panel attributes from
`$E748` once, at each start of play (SavePanel `$A98D` keeps them there while another page covers them).
From then on the code touches only small parts of it:

| Mark | Part | Address | Writer | When |
| ---: | --- | --- | --- | --- |
| 1 | the score | `$5802` (row 0, column 2) | PrintPlayerScore `$A4AE` | ScoreJob, after each award |
| 2, 3 | the spinners | `$5A81`, `$5A9D` (row 20, columns 1 and 29) | DrawSpinner `$A8BE` | each pass (PanelFrame) |
| 4 | the pod icon | `$5086` (rows 20-21, columns 6-7) | PodIconJob `$AC2C` | the start of play, each pod taken |
| 5 | the ink step | `$5AC6` | PanelFrame `$AB13` | every fourth pass |
| 6, 7 | the fuel lamps | `$5AC1`, `$5ADD` | PanelFrame | each pass |
| 8 | the speed bar | `$5AEE`-`$5AF1` | PanelFrame | each pass |
| 9 | the burst | rows 21-22, columns 11-20 | PanelFrame | every other pass while PanelBurst `$7F77` runs |
| 10 | the lives | `$5AD8` (row 22, column 24) | DrawLives `$A4EF` | the start of play, an extra life |

![w1 frame 2200: the score line and the panel x3, each part the code writes boxed and numbered; the five pod icons; the gauges](img/hud/panel.png)

```sh
python3 tools/fig_panel.py --npz work/zyB/w1-frames.npz --frame 2200
```

How to read:

- Top: row 0 and rows 19-23 of w1 frame 2200 at 3× scale. Each box is one part of the table above, numbered as
  in the list on the right.
- Middle: the five icons of PodIcons `$B4AF`, 32 bytes each, coloured as PodIconJob colours them (8.3).
- Bottom: the fuel lamps and the speed bar cut from w1 8 frames after each state was first reached (the screen
  shows a new value a frame or more after it is set).

## 8.2 PanelFrame: attributes only

PanelFrame `$AB13` (hud.asm) runs once a pass from the play interrupt (at `$AA87`) and writes only attributes of
rows 20-23 (`$5A80-$5AFF`):

1. **The ink step:** the ink of `$5AC6-$5AC7` + 1 every fourth pass (PassCount `$7F62` AND 3 = 0).
2. **The speed bar:** `$5AEE-$5AF1` = `$01` (dark), then (speed >> 5) - 1 cells of `$31` from the left. Speed `$40`
   lights 1 cell, `$60` 2, `$80` 3, `$A0` 4.
3. **The fuel lamps:** DE = `$3131`, stored at `$5AC1` and `$5ADD` (E at the address, D after it). Fuel below `$40`
   makes D `$01`: the right lamp of each pair dark. Below `$20` E too: both dark.
4. **The spinners and their colour:** SpinnerFrame `$7F78` + (PassCount AND 1), 0-15; SpinnerColour `$7F79` moves
   by its step on odd passes and turns at 7 or 1; DrawSpinner draws both spinners (8.4).
5. **The burst:** on even passes rows 21-22 columns 11-20 are cleared; while PanelBurst `$7F77` is not 0 it counts
   down and its value n is the attribute of columns 15 + n and 16 - n: a pair of cells walks out from the middle.
   FireLaser `$9C1D` sets it to 6 (at `$9C80`) when it is 0, so the burst follows the laser.

The gauges as w1 saw them (the bottom of the figure, attribute bytes read from the screen of `w1-frames.npz`):

| w1 frame | Fuel `$80E6` | `$5AC1` | `$5AC2` | Shown |
| ---: | --- | --- | --- | --- |
| 109 | `$4D` | `$31` | `$31` | both lamps lit |
| 3269 | `$3F` | `$31` | `$01` | the right lamp dark |
| 3735 | `$11` | `$01` | `$01` | both dark |
| 4100 | `$54` | `$31` | `$31` | lit again after FuelOut (10.4) |

The pairs at `$5ADD`-`$5ADE` had the same bytes at all four frames.
The speed bar crops: speed `$40` at frame 109 (one lit cell), `$60` at 209 (two).

## 8.3 The pod icon

PodIconJob `$AC2C` (event bit 2) draws the icon of the selected pod:

- n = the player record's `+7` (the selector, 0-4); the icon is PodIcons `$B4AF` + 32 n, 16 × 16 pixels.
- IconRow `$AC5E` draws it as two 2-cell rows at `$5086` and `$50A6`: screen rows 20 and 21, columns 6-7.
- The attributes: `$46` (bright yellow ink) on the top row `$5A86-$5A87`, `$45` (bright cyan) on the bottom row
  `$5AA6-$5AA7`.
- While it runs, only event bit 7 may interrupt it (EventMask AND `$80`).

Posted by the play loop's start (`$B1C7`) and by PodStep (`$A243`) for every pod taken, so the icon steps with the
selector (10.2). The five icons, in the selector's order: the speed-up, the laser, the plasma, the homing
missiles, the seeker.

## 8.4 The spinners

Two 16 × 16 spinners turn at row 20, columns 1 and 29 (panel.asm):

- 5 shapes are stored as their left 8 pixels only (SpinnerImages); the right half is the bit mirror, from the
  bit-reverse table `$FB00`.
- SpinnerFrames maps the frame 0-15 to an offset: an even offset reads a shape top down, an odd one bottom up (the
  shape upside down). So 5 stored shapes give 16 frames.
- DrawSpinner `$A8BE` writes the pixels (DrawSpinnerRow, DrawSpinnerFlippedRow) and the attribute of the four
  cells.

## 8.5 Code against screen: who writes the panel

![w2 frames 6355-6460: the screen at the window's end, who wrote each byte last, and the panel zoomed](img/hud/writers-panel.png)

```sh
python3 tools/fig_writers.py --out docs/img/hud/writers-panel.png --zoom 0,152,128,40 --title "Code vs screen of the panel, w2 frames 6355-6460 (the start of level 1): RestorePanel (\$A982)\ncopies the picture once, then PanelFrame's parts and DrawSpinner rewrite only their cells" -- --trace work/zyB/w2/traces/6355_0-6460_0.uatr --work work/zyB/w2 --listing build/game.lst
```

`tools/fig_writers.py` runs `kit/writers_map.py` on the trace and stacks its four panels two by two.

How to read:

- Top left: the screen at the window's end. Below it: each screen byte coloured by the routine that wrote it last.
- Right: the box (x 0-127, y 152-191: the left half of the panel) zoomed, above the same box's writers.
- The legend lists the writers with the bytes they wrote last and their writes in the window, and the instruction
  addresses that wrote.

What it shows (105 frames from the end of the level 0 banner into level 1):

- RestorePanel: 2208 writes, 1648 bytes last. The `LDIR` at `$A982` copies the 2048 bytes of the third, `$A98A` the
  160 attribute bytes.
- After it only the parts of 8.1 write the panel: the spinners (DrawSpinner, DrawSpinnerRow), the burst
  (PanelClearRow, 528 writes), the ink step (PanelInkStep), the fuel lamps (PanelFuelLamps, 4 bytes), the speed bar
  (PanelSpeedBar, 1 byte).
- The score: PrintCharBold wrote 96 bytes, 12 character cells of 8 lines on the score line.
- The playfield above is written by the drawing code of 06 (RowStart, StripCellPlain, RowStar).

## 8.6 Score, lives and the score job

The score is 4 BCD bytes at the player record's `+0`-`+3`, high first.

- AddScore `$A489` adds award A of PointsTable `$8231` (10.5) and posts event bit 1.
- ScoreJob `$AC7A` (event bit 1): PrintPlayerScore, WeaponRating (10.6), and the extra-life test against
  ExtraLifeScores `$800F`.
- PrintPlayerScore `$A4AE`: player 1 at column 2, player 2 at column 22 of row 0; `$47` (bright white) for the
  player in play, `$05` (cyan) for the other; leading zeros as spaces (PrintBcd `$A43E` with its copy in BcdScratch
  `$7FFC`).
- DrawLives `$A4EF`: six marks from `$5AD8`, the steps between them in LifeSteps `$81C0`. The first `+4` marks are
  red on black (`$42`), the rest black.
- SpriteBuildJob (bit 7) outranks both: the jobs run in the play loop, highest bit first (EventDispatch `$AC07`),
  and the score and the icon allow only bit 7 while they run.

w2 frame 7264 shows the chain in one frame: the selector wraps (1100 points), the score is printed as 10425, the
lives go 2→3 and a third red mark appears.

## 8.7 The print routine

PrintString `$A401` prints bytes up to `$FF` through PrintChar `$A321`:

| Byte | Meaning | Routine |
| --- | --- | --- |
| `$00` n | the attribute = n | PrintSetAttr `$A3B1` |
| `$01` n | the ink = n | PrintSetInk `$A3B6` |
| `$02` n | the paper = n | PrintSetPaper `$A3BF` |
| `$03` n | the column = n | PrintSetColumn `$A3CD` |
| `$04` n | the row = n | PrintSetRow `$A3D6` |
| `$05` n | the column + n (the low byte only, no carry into the row) | PrintColumnRight `$A3ED` |
| `$06` n | the row + n | PrintRowDown `$A3F4` |
| `$1B` n | message n, then go on | PrintString |
| `$20`-`$7F` | a ROM character, "split bold" | PrintChar |
| `$80`-`$B5` | one of the game's 54 glyphs | PrintChar |
| `$FF` | the end | PrintString |

The state:

- PrintPos `$80AA` is an attribute address (`$5800-$5AFF`): the row and the column in one word.
- The screen address of the cell's first line: the attribute's high byte rotated left 3 times, XOR `$82` (`$58` →
  `$40`, `$59` → `$48`, `$5A` → `$50`), the low byte the same.
- PrintAttr `$80AC` is the attribute written with each character; PrintPending `$80AD` holds a code waiting for its
  byte (`$20` none).
- PrintMessage `$A423` finds message n by counting n + 1 `$FF` bytes from `$82ED`: the messages are a list, not a
  table of pointers.

## 8.8 Two fonts

![The ROM characters as the ROM draws them and as PrintChar prints them, and the 54 game glyphs](img/hud/font.png)

```sh
python3 tools/fig_text.py font
```

How to read:

- Top left: the ROM characters `$20-$7F` from `$3C00` as the ROM prints them. Top right: the same codes as
  PrintChar prints them.
- Bottom: the game's glyphs `$80-$B5`, 8 bytes each as they are stored, with their codes.

The "split bold" ROM font:

- ROM line 0 (always blank) is dropped; ROM line 1 is printed on line 0, line 1 is left blank, ROM lines 2-7 go on
  lines 2-7. Capitals get a gap under their top bar.
- Each byte is printed as (b << 1 AND `$F0`) OR b: the left nibble emboldened by one pixel, the right nibble as it
  was.
- The routine for it is PrintCharBold; PrintRomGlyph reads the ROM.

The game glyphs:

- 54 glyphs at `$B54F`; the address of code c is c × 8 + `$B14F`.
- `$80-$A3` build the ZYNAPS logo, `$A4-$B5` the HEWSON lettering (messages 0 and 2).

## 8.9 The messages and their pages

28 messages follow each other from `$82EE`, each ending with `$FF` (src/res/text/messages.msg.txt).
Messages call messages (`$1B` n), so a page is one message that prints others:

| Message | Contents | Printed by |
| ---: | --- | --- |
| 0 | the ZYNAPS logo in glyphs, three colours | 1, 13, 19, 25 |
| 1 | row 0, then 0 | 7 |
| 2 | the HEWSON lettering | 21 |
| 3-6 | frame pieces (3 and 4), five of each (5 and 6) | 7 |
| 7 | the border of the credits page | 21, 22 |
| 8 | `.....` in cyan (the high-score line's dots) | the high-score table |
| 9-12 | `CS`, `SS`, `SP`, `EN`: key names for CAPS SHIFT, SYMBOL SHIFT, SPACE, ENTER | PrintKeyName (menu.asm: key codes 0-3 + 9) |
| 13 | the logo and `KEYBOARD  DEFINITION` | the key definition (menu.asm) |
| 14-18 | `FIRE`, `UP`, `DOWN`, `LEFT`, `RIGHT`, each 3 rows down | the key definition, one prompt a key |
| 19 | the logo, `SELECTIONS`, `1 PLAYER`, `2  PLAYERS` | the player selection (options.asm) |
| 20 | `DOMINIC ROBINSON` | 21 |
| 21 | the credits: by Dominic Robinson, graphics Steve Crow, the HEWSON lettering | CreditsPage `$B095` |
| 22 | the credits border alone | HiScorePage `$B0C9` (under the table) |
| 23 | `PLAYER n` | 24, 25 |
| 24 | `PREPARE FOR COMBAT`, `PLAYER n` | LevelStart `$AF49` (the level banner) |
| 25 | the logo, `ROLE OF HONOUR`, `PLAYER n` | HighScoreEntry (hiscore.asm) |
| 26 | `UNRANKED` | HighScoreEntry, no place in the table |
| 27 | `ENTER YOUR INITIALS` | HighScoreEntry, a place |

![The pages the 28 messages make, printed by a model of PrintString on blank screens](img/hud/pages.png)

```sh
python3 tools/fig_text.py pages
```

How to read:

- Six blank screens, each printed by the model with the messages named in its title: the credits (21), the keys
  (13, then 14-18), the selections (19), the level start (24), the role of honour (25 and 27), no rank (25 and 26).
- `n` in `PLAYER n` is PlayerDigit `$84BB` as stored; the game writes the player's digit there before printing.
- Every one of the 28 messages appears in one of the six pages.

The model (`tools/fig_text.py`, class Printer) follows print.asm code for code. The key-definition page leaves the
key names out: the game prints each key's own character, or messages 9-12 for the four keys without one
(PrintKeyName, menu.asm).

The high-score table (ROLE OF HONOUR) is a list of 5 lines `$8261-$82A6`, each a row, a column, three initials,
message 8 (the dots) and a BCD score: EGO 68000, DFR 25000, BAV 10000, HNR 5000, BMR 1000.

## 8.10 What stays unexplained

- LifeSteps `$81C0` has 5 bytes; DrawLives reads 6, the sixth is EventRequests `$81C5`. The sixth step is added
  after the last mark is written, so it moves nothing drawn: a harmless over-read.
- PrintBcdSpaces `$A43C`: an entry two bytes before PrintBcd that nothing calls.
- Message 1 (row 0, then the logo) is printed only inside message 7; no code prints it alone.
