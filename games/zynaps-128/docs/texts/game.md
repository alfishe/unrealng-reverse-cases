# Zynaps 2 in 1: the texts of the game

The game is block 2 (Hrust 1), relocated to the 48K original's addresses: its texts sit where the Hewson game has
them, and only one of them changed ([differences.md](differences.md)). All of them are English; no translation is
needed (`ROLE OF HONOUR` is the game's own spelling of "roll of honour", the high-score table).

Source: the memory at the game's entry (`work/images/game-entry-cpu.bin`), read by
`python3 tools/game_text.py work/images/game-entry-cpu.bin --markdown` (`$83B0`-`$8516`); the key names and the
table from the same image.
Positions (character row 0-23, column 0-31) are the print routine's control codes as decoded by the 48K case
(`R/games/zynaps/work/stage1/texts.txt`, the same bytes) and were checked against the screen dumps of the
recordings named below (the rows and columns where ink is, `tools/compare_shots.py` dumps).

Recordings: `c1` = `work/stage1/c1/session.ttd` (Pentagon 128, power-on to play), `k128` =
`work/stage2/compare/k128/session.ttd` (power-on to the keyboard definition).

## The game menu: the credits page

`c1` frame 3460 ([08-credits](../img/compare/08-credits.png), right; `work/stage1/screens/08-game-menu.png`). The
menu shows this page and the high scores in turn.

| Address | Text | Row, column |
| --- | --- | --- |
| | the `ZYNAPS` logo, top and bottom, and the `HEWSON` plate (graphics characters) | rows 0-3, 8, 20-22 |
| `$844B` | `BY` | 5, 15 |
| `$8430` | `DOMINIC ROBINSON` | 6, 8 |
| `$8459` | `GRAPHICS` | 12, 12 |
| `$8467` | `STEVE CROW` | 13, 11 |
| `$8430` | `DOMINIC ROBINSON` (the same string again) | 14, 8 |
| `$8479` | `MUSIC` | 16, 13 |
| `$8484` | `DAVE ROGERS ` (the 48K original: `STEVE TURNER`) | 17, 10 |
| | the two players' scores `00000000` | 21, 0 and 21, 24 |
| `$8496` | `COPYRIGHT` | 23, 0 |
| `$84A1` | `HEWSON 1987` | 23, 21 |

## The high-score page

`c1` frame 3540 ([07-high-scores](../img/compare/07-high-scores.png), right; `work/stage1/screens/09-high-scores.png`).
The table at `$8261`: five entries of 14 bytes (a print string with the initials, then the score in four BCD bytes).

| Address | Text | Row, column |
| --- | --- | --- |
| `$8261` | `EGO........68000` | 6, 8 |
| `$826F` | `DFR........25000` | 9, 8 |
| `$827D` | `BAV........10000` | 12, 8 |
| `$828B` | `HNR.........5000` | 15, 8 |
| `$8299` | `BMR.........1000` | 18, 8 |

## Keyboard definition (key 3)

`k128` frame 3900 ([06-keyboard-definition](../img/compare/06-keyboard-definition.png), right;
`work/stage1/screens/14-keyboard-definition.png`). The key names in the right column are the keys pressed; the
recording typed the 128K defaults.

| Address | Text | Row, column |
| --- | --- | --- |
| `$83B2` | `KEYBOARD  DEFINITION` | 5, 6 |
| `$83CB` | `FIRE` | 8, 9 |
| `$83D6` | `UP` | 11, 9 |
| `$83DF` | `DOWN` | 14, 9 |
| `$83EA` | `LEFT` | 17, 9 |
| `$83F5` | `RIGHT` | 20, 9 |
| `$8198` | the key name (column 22): one per key, below | 8-20, 22 |

The key names (`$8198`, 40 entries in the order of the keyboard half-rows `$FEFE`..`$7FFE`, bit 0 first; the four
two-letter names are printed as messages):

```
CS Z X C V   A S D F G   Q W E R T   1 2 3 4 5
0 9 8 7 6    P O I U Y   EN L K J H  SP SS M N B
```

`CS` caps shift, `SS` symbol shift, `SP` space, `EN` enter.

The defaults (the key table `$8188`, five pairs of half-row and bit mask, in the order fire, up, down, left,
right): `7F 01`, `FB 01`, `FD 01`, `DF 02`, `DF 01` = **SP, Q, A, O, P**. Typed on this screen they leave the table
unchanged (read back at `k128` frames 3500 and 4000).

## Selections (key 1 or 2)

`work/stage1/screens/13-selections.png` (the stage 1 exploration).

| Address | Text | Row, column |
| --- | --- | --- |
| `$8405` | `SELECTIONS` | 5, 11 |
| `$8413` | `1 PLAYER` | 9, 12 |
| `$841F` | `2  PLAYERS` | 13, 11 |

## The start of a game

`c1` frame 3945 ([09-prepare-for-combat](../img/compare/09-prepare-for-combat.png), right;
`work/stage1/screens/15-prepare-for-combat.png`).

| Address | Text | Row, column |
| --- | --- | --- |
| `$84C1` | `PREPARE FOR COMBAT` | 9, 7 |
| `$84B4` | `PLAYER n` (n = the player, 1 or 2) | 11, 12 |

## The end of a game

`c1`, the game-over screens `work/stage1/screens/16-role-of-honour.png` and `17-role-of-honour-unranked.png`.

| Address | Text | Row, column |
| --- | --- | --- |
| `$84DE` | `ROLE OF HONOUR` | 5, 9 |
| `$84B4` | `PLAYER n` | 9, 12 |
| `$84F5` | `UNRANKED` | 11, 12 |
| `$8502` | `ENTER YOUR INITIALS` | 11, 6 |

`ENTER YOUR INITIALS` (a score good enough for the table) was not reached in any 128K recording (every game was
`UNRANKED`); the bytes are the 48K original's, whose case shows the screen
(`R/games/zynaps/work/stage1/screens/11-enter-initials.png`).

## In play

The play screen (`c1` frame 4020, [10-play-start](../img/compare/10-play-start.png)) has no text besides the score
digits and the panel's graphics.

## Not shown

`$FFD9`-`$FFFE` held five 6-byte glyphs in the 48K original (bitmaps, not text); the 128K version clears them. No
other text-like bytes differ.
