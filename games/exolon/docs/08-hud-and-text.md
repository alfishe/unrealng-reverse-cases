# 8. HUD and text

What this covers:

- the HUD on rows 22 and 23: its labels, its five numbers and who prints them;
- PrintString `$AF2B`, the one string printer the game uses for text, the HUD and all the scenery, with every code;
- the five plot modes behind it;
- the font, the logo and the tile area;
- the score, which is a string;
- the text screens: menu, define keys, GAME OVER, name entry, Hall of Fame, the round end and the bonus screen.

The recordings it rests on:

- `x1` (`tests/inputs/x1-right.txt` on `entry.z80`, no POKE): the game's start at frame 184 (the HUD drawn), GAME
  OVER at frame 2750.
- `m1` (`tests/inputs/m1-menus.txt`, no POKE): define keys, the menu options.
- `h1` (`tests/inputs/h1-hall-of-fame.txt` on `entry-score.z80`, a clone with the score set to 009000 and its reset
  removed; exploration only): the name entry and the whole Hall of Fame roll.
- the warp run `w/124` (a clone on screen 124; exploration only): CONGRATULATIONS and the bonus screen.
- the image (`work/mkgame/original.bin`) for the strings, fonts and the printer model in `tools/fig_docb.py`.

Scope: the scenery that PrintString draws is in [7. Objects](07-objects.md#71-three-cell-maps-and-the-build); the
pixel routines are in [6. Rendering](06-rendering.md); the bonus and Hall of Fame rules are in
[10. Gameplay logic](10-gameplay-logic.md).

## 8.1 The HUD

The HUD is rows 22 and 23. DrawHud `$7690` prints it once, when a game starts:

```asm
DrawHud:
  LD HL,HudText
  CALL PrintString
  CALL PrintAmmo
  CALL PrintGrenades
  CALL PrintLives
  JP PrintZone
```

HudText `$76A2` prints the labels on row 22 and clears row 23.
The numbers on row 23 come from five printers:

| Field | Row, column | Attribute | Printer | Value |
| --- | --- | --- | --- | --- |
| AMMO label | 22, 0 | `$45` bright cyan | HudText | |
| GRENADES label | 22, 5 | `$46` bright yellow | HudText | |
| POINTS label | 22, 14 | `$44` bright green | HudText | |
| LIVES label | 22, 21 | `$47` bright white | HudText | |
| ZONES label | 22, 27 | `$43` bright magenta | HudText | |
| ammunition | 23, 1 | `$47` | PrintAmmo `$8E4F` (two digits) | Ammo `$8E5A`, 0-99 |
| grenades | 23, 8 | `$43` | PrintGrenades `$8E5B` | Grenades `$8E66`, 0-10 |
| score | 23, 14 | `$45` | ScoreText `$AD82` through PrintString | Score `$AD8A`, six ASCII digits |
| lives | 23, 23 | `$46` | PrintLives `$8E67` (one digit) | Lives `$8E7A`, 0-9 |
| zone | 23, 28 | `$46` | PrintZone `$8E7B` (three digits, PrintNumber3 `$B0C6`) | ScreenNumber `$8523` |

The attribute bytes of row 22 read in `x1` from frame 185 on: `45 45 45 45 45 46 ... 44 ... 47 ... 43`, the five
label colours in the table.

The ZONES field shows the screen number, 0-124, not the zone (`x2` counts it 0 to 5 over its first 3000 frames).

PrintAmmo and PrintGrenades print through PrintTwoDigits `$8E1D` (HudDigit `$8E37` divides by 100, 10 and 1 and
prints the tens and units), PrintLives one digit, PrintZone three; all of them with PrintCharAttr, the printer that
writes the attribute with each glyph.
Each is called again whenever its value changes: FireControl, the pods, the death and the grenade start.

![x1 frame 184: which routine wrote each byte of the HUD as the game starts](img/hud/writers-hud.png)

```sh
python3 tools/fig_hud.py writers
# runs: python3 ../../kit/writers_map.py --work work/docs/docB/x1 --window 184:0-185:0 --listing build/game.lst \
#   --out work/docs/docB/writers-hud-raw.png --view screen --scale 3
# and lays its panels and legend out 900 px wide
```

How to read:

- Top left: the screen at the end of `x1` frame 184, the frame in which DrawHud runs (the row 22 attributes are 0 at
  the end of frame 183 and set at the end of 184; TTD reads at every frame).
- Top middle: each byte of the screen coloured by the routine that wrote it last in the frame; grey was not written.
- Middle: the boxed HUD rows 22-23 of both views enlarged 3 times.
- The legend (from `kit/writers_map.py`) counts bytes and writes per routine, and the instructions that did them.

What it shows:

- PrintCharLine (red, the inner loop of PrintChar `$ADE1`, plot mode 0) writes the labels, the blanks of row 23 and
  the score: 504 bytes.
- PrintCharAttrLine (blue) writes the four numbers AMMO, GRENADES, LIVES and ZONES: 72 bytes, 9 glyphs.
- ClearScreenAttr (green) writes the attributes of the playfield: the screen is cleared in the same frame, and the
  scenery comes later (BuildScreen).
- The score is not a number printer's job: it is a string (8.5).

## 8.2 The string printer `$AF2B`

PrintString takes HL = the string, D = the row, E = the column, C = the attribute.
It reads one byte at a time:

| Byte | Meaning |
| --- | --- |
| below `$61` | a glyph: print it, the column + 1 |
| `$61-$8F` n | a move: the row + (code - `$78`), the column + n (signed) |
| `$90-$CE` | the next row, the column + (code - `$AF`) |
| `$CF-$DE` | the ink: code - `$CF`; 8-15 are inks 0-7 bright; the paper is kept |
| `$DF` r c | the cursor to row r, column c |
| `$E0` a | the attribute a |
| `$E1` n ... `$E2` | repeat the bytes between n times; the attribute is put back on each pass |
| `$E3` lo hi | a sub-string at hi lo; the cursor and the attribute are kept round it |
| `$E4` n g | glyph g n times across |
| `$E5` n g | glyph g n times down |
| `$E6` lo hi | the glyph set: glyph g is at hi lo + 8 g |
| `$E7` | a space from FontBase `$D7E0` |
| `$E8` n | CellTypes n for the cells printed next |
| `$E9` / `$EA` | OpenCells 0 / `$FF` for the cells printed next |
| `$EB` n | CellTypes n at the cursor, nothing printed, no move (plot mode 0 only) |
| anything else | the end |

```asm
PrintString:
  LD A,(HL)
  INC HL
  CP $61
  JP NC,PrintStringMove
  CALL PrintChar          ; the plot mode's routine (operand $AF33 set by
                          ; SetPlotMode)
  INC E
  JP PrintString
PrintStringMove:
  CP $90                  ; $61-$8F: a relative move, the row from the code,
                          ; the column from the next byte
  JP NC,PrintStringNewLine
  SUB $78
  ADD A,D
  LD D,A
  LD A,(HL)
  ADD A,E
  LD E,A
  INC HL
  JP PrintString
PrintStringNewLine:
  CP $CF                  ; $90-$CE: the next row, the column moved by code -
                          ; $AF
  JP NC,PrintStringInk
  INC D
  SUB $AF
  ADD A,E
  LD E,A
  JP PrintString
  ; ...
PrintStringCall:
  CP $E3                  ; $E3 lo hi: the sub-string, position and attribute
                          ; kept
  ; ...
  PUSH BC
  PUSH DE
  CALL PrintString
  POP DE
  POP BC
```

```text
loop:
    b = mem[hl]; hl += 1
    if b < $61:  print glyph b at (row, col); col += 1
    elif b < $90: row += b - $78; col += signed(mem[hl]); hl += 1
    elif b < $CF: row += 1; col += b - $AF
    elif b < $DF: attr = (attr AND $38) OR ink(b - $CF)
    elif b == $DF: row, col = mem[hl], mem[hl+1]; hl += 2
    elif b == $E3: PrintString(word(mem[hl]), row, col, attr); hl += 2   # row, col, attr kept
    ...                                                                   # the table above
    else: return
```

A worked example from MenuText: after "DEFINE KEYS" the bytes are `7A F4 DA 33 DC 20 4B 45 59 42 ...`.

- `$7A` is a move: the row + (`$7A` - `$78`) = 2; the next byte `$F4` = -12 moves the column back 12.
- `$DA` sets ink `$DA` - `$CF` = 11: ink 3 bright, magenta.
- `$33` prints the glyph "3". `$DC` sets ink 13: ink 5 bright, cyan.
- `$20 4B 45 59 ...` print " KEYB...". So option 3 sits two rows under option 2, at the same column, its digit in
  magenta and its text in cyan.

A second example, a new line: `$AD` gives the next row and the column + (`$AD` - `$AF`) = -2. After two glyphs at
columns 4 and 5 the cursor is at column 6; `$AD` brings it to column 4 of the next row, under the first glyph. The
elements build their 2 x 2 tiles this way (element 19, the ammunition pod: `... $00 $E8 $00 $D6 $01 $AD ...`).

### Two strings through the model

![HudText: each byte coloured by its code, the model's rendering of rows 22-23, and x1's rows 22-23](img/hud/strings-hud.png)

![MenuText: each byte coloured by its code, the model's menu, and the menu of h1](img/hud/strings-menu.png)

```sh
python3 tools/fig_hud.py strings   # both figures
```

How to read:

- Top of each figure: the bytes of the string, 16 a row (the row's address on the left, the offset on top), coloured
  by the code they belong to (the legend at the bottom). The first byte of a code is solid; its operands are paler.
  Glyph bytes show their letter.
- Below: the string run through the printer model (`tools/fig_docb.py print_string`), sub-strings followed, and the
  same place in a recording: rows 22-23 of `x1` frame 250, the menu of `h1` frame 8000.

What it shows:

- HudText is 56 bytes and 45 codes: `$DF 16 00` (row 22), `$E6 E0 D7` (the font), `$E8 01 $E9` (the HUD cells are
  solid and drawn), five inks with their labels, `$DF 17 00` and `$E4 20 20` (32 spaces), and the sub-string
  `$E3 82 AD`, the score.
- The model's rows 22-23 equal the recording's except the four numbers, which the HUD's number printers add.
- MenuText is 146 bytes and 128 codes. It starts with `$E8 01`: the 154 cells it prints are marked solid in
  CellTypes, and the menu's stars (MenuSparkles) only twinkle on cells left at 0. The logo is a sub-string
  (LogoText `$70FF`).
- The recording's "5 KEMPSTON" is white, not cyan: HighlightControl `$6F90` paints the current control option
  bright white after the text is printed.

## 8.3 Five plot modes

PrintString does not draw a glyph itself.
Four `CALL` operands inside it (`$AF33`, `$AFC0`, `$AFD2`, `$AFFE`) hold the address of the glyph routine.
SetPrinter `$99F8` patches all four from Printers `$9A0F`:

| Mode | Routine | What it does | Users |
| ---: | --- | --- | --- |
| 0 | PrintChar `$ADE1` | the glyph, its attribute, CellTypes and OpenCells written; columns with bit 5 set (32-63, or negative) are clipped | every string by default |
| 1 | PrintCharAttr `$AE26` | the glyph and attribute only | the HUD numbers, name entry, bonus screen (called directly) |
| 2 | XorCharAttr `$AE5D` | the glyph by XOR | no string; AnimateTurrets calls it directly for the recoil frames |
| 3 | EraseBlockDebris `$AE95` | XOR, the maps cleared, two debris pieces a glyph | MineBlast, GrenadeBlast |
| 4 | EraseBlock `$AEE4` | XOR, the maps cleared | Pods (a taken pod erased by printing it again) |

Every caller of modes 3 and 4 sets mode 0 again after its print.
So a destructible piece of scenery is erased by printing its own element string again in mode 3: the same codes
that drew it walk the same cells and take them away, with debris.

## 8.4 The font, the logo and the tile area

![The 59-glyph font, each glyph over its code, and the logo](img/hud/glyphs.png)

![The tile area: 593 cells, yellow where a scenery element prints them](img/hud/tiles.png)

```sh
python3 tools/fig_hud.py glyphs    # both figures
```

How to read:

- First figure, top: Font `$D8E0`, the codes `$20-$5A` (FontBase `$D7E0` + 8 x code), each with its code under it.
- First figure, bottom: LogoText `$70FF` run through the model; the title gives its cells and its glyph set.
- Second figure: the tile area `$DAB8-$ED3F` as 593 cells of 8 bytes, 32 a row, every second row's address on the
  left. Yellow: a cell some element prints (the model run over all 62 elements, `$E6` bases followed); grey: no
  element prints it.

What it shows:

- Text uses one font of 59 glyphs: space, punctuation, an arrow, digits and capitals. There are no lower-case letters.
- The logo is 50 cells from glyph set `$E6B0`. The menu and define keys print it as the sub-string `$E3 FF 70`; the
  other text screens in 8.6 show the same logo.
- The 62 elements print 483 of the 593 tile cells, through 22 glyph-set bases (`$DAB8` to `$EC48`). A base is not a
  separate table: elements open windows into one area, and windows overlap.
- The grey cells are the logo, the turret's recoil frames (font `$DDD8`, mode 2), the frame pieces of the text
  screens and the menu digits.

## 8.5 The score is a string

The score has no binary form.
Score `$AD8A` is six ASCII digits inside ScoreText `$AD82`:

```text
$AD82  E0 45        attribute $45
$AD84  E6 E0 D7     glyph set $D7E0
$AD87  DF 17 0E     row 23, column 14
$AD8A  30 30 30 30 30 30   "000000"
$AD90  FF           end
```

AddScore `$AD53` adds a six-digit ASCII addend digit by digit and prints the string again:

```asm
AddScore:
  ; ...
  LD C,$00
  LD HL,Score+$0005
  LD B,$06
AddScoreLoop:
  LD A,(DE)
  ADD A,(HL)
  SUB $30
  ADD A,C
  CP $3A
  LD C,$01
  JR C,AddScoreNoCarry
  SUB $0A
  JR AddScoreDigit
AddScoreNoCarry:
  DEC C
AddScoreDigit:
  LD (HL),A
  DEC HL
  DEC DE
  DJNZ AddScoreLoop
  ; ...
  LD HL,ScoreText
  CALL PrintString
```

```text
carry = 0
for i in 5 down to 0:
    d = score[i] + addend[i] - '0' + carry      # an ASCII digit, perhaps past '9'
    if d > '9': d -= 10; carry = 1 else: carry = 0
    score[i] = d
PrintString(ScoreText)
```

DE points at the last digit of an addend in PointValues `$AD91`: ten addends of 6 ASCII digits for 25, 50, 100,
125, 150, 200, 250, 300, 350 and 1000 points.

A worked example: score "000975" plus "000050". Digit 5: `'5' + '0' - '0'` = `'5'`, no carry. Digit 4:
`'7' + '5' - '0'` = `'<'` (`$3C`), past `'9'`: `$3C - 10` = `'2'`, carry 1. Digit 3: `'9' + '0' - '0' + 1` = `':'`,
past `'9'`: `'0'`, carry 1. Digit 2: `'0' + 1` = `'1'`. The result is "001025".

The Hall of Fame compares and copies these same ASCII digits ([10.9](10-gameplay-logic.md#109-the-hall-of-fame)).

## 8.6 The text screens

![Eight text screens from m1, h1, x1 and the warp run w/124](img/hud/screens.png)

```sh
python3 tools/fig_hud.py screens
```

How to read:

- Eight screens saved by the recordings every 250 frames; the title of each gives the recording and the frame.
- `h1` and `w/124` are clones (exploration only): the score clone reaches the name entry, the warp run reaches the
  round end.

What it shows, with the code behind each:

- Define keys (DefineKeys `$6FAB`): "SELECT KEY FOR...." and the five actions, the keys pressed printed next to
  each. A name typed here can be the cheat word ([10.10](10-gameplay-logic.md#1010-the-zorba-cheat)).
- The menu (MainMenu `$6DA1`, MenuText `$6E17`): the logo, "BY RAFFAELE CECCO", five options, the copyright line.
  Stars twinkle only on free cells (8.2).
- GAME OVER (GameOver `$A02A`): a red box printed over the playfield; the jingle plays
  ([9.3](09-sound.md#93-beeper-tunes-on-48k)).
- The name entry (`$A095`): the frame of pieces, "CONGRATULATIONS! PLEASE ENTER YOUR NAME INTO THE EXOLON HALL OF
  FAME", the name under a cursor `?`, "PRESS CAPS TO DELETE", "PRESS ENTER TO END". `h1` typed EXOLON.
- The Hall of Fame (HallOfFameRoll `$7149`): the logo and the planets stay, the table scrolls one pixel line a step
  in columns 8-23, 960 steps for the 50 entries and 10 empty ones. `h1` ran the whole roll.
- CONGRATULATIONS (`$AA3F`, at the round end on screen 124): "YOU HAVE PROVEN YOUR COMBAT ABILITIES TO THE FULL",
  "PRESS FIRE TO RESUME PLAY".
- The bonus screen (BonusScreen `$A8DB`): "EXOLON BONUS SCREEN! PRESS FIRE TO STOP POINTER", eight lines 00000 to
  07000 POINTS, and the pointer.

## 8.7 What no recording reached

- The CAPS delete of the name entry (`$A102-$A121`): no run pressed CAPS SHIFT there.
- PrintChar's clip of columns 32-63: known from the code (bit 5 of E tested); no recording shows a string printed
  past the right edge.
- Plot mode 2 through SetPrinter: no caller selects it; XorCharAttr runs only by direct calls (the turret).
