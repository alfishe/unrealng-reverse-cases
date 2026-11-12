# Resources

Every resource out of the code, in an editable format; `tools/res_formats.py build` turns them back into the bytes
the sources INCBIN, `tools/res_formats.py check` proves the round trip (20 editable files here, 216 with the
variants'; the 4 files of `spare/` are bytes). kit/mkgame.py `--install` writes them from the images through `install()`. The parts: the menu
(`src/main`), the music (`src/music`) and the BASIC sector (`src/basic`).

These files are what the variants change: a variant folder (`variants/NAME/`) holds the ones that differ, under the
same names and in the same formats, and `tools/build.sh --variant NAME` builds it over this folder
([variants/README.md](../../variants/README.md)).

| File | What | Format | Entry |
| --- | --- | --- | --- |
| `graphics/font.png` | the menu's font: 96 characters, space to the copyright sign | PNG sheet, 8 x 8, 16 a row | Font `$A600` (768 bytes) |
| `graphics/logo.png` | the ZYX logo: four 40 x 40 sprites (the Z takes two) | PNG sheet, 40 x 40, 4 a row | Logo `$A900` (800 bytes) |
| `graphics/rhombus.png` | the corner rhombus the phases are built from | PNG, 40 x 40 | RombSource `$6E98` (200 bytes) |
| `graphics/twinkle.png` | the 4 twinkle frames | PNG sheet, 16 x 16, 4 a row | TwinkleSprites `$6F60` (128 bytes) |
| `tables/logo-attrs.txt` | the logo's attributes, 5 rows of 20 cells | hex rows | LogoAttributes `$AC20` (100 bytes) |
| `tables/corner-colours.txt` | the corner gradients' five attributes | hex | CornerColours `$ADF4` (5 bytes) |
| `tables/stars.txt` | the falling stars: three tables of 20 | points `x y lit` | StarsA `$AC84` (360 bytes) |
| `tables/keys.txt` | the letter keys A-X: half-row and bit | `letter: row %mask` | KeyTable `$6B53` (24 bytes) |
| `tables/phase-order.txt` | the rhombus phase of each of the 32 steps of a turn | numbers | PhaseOrder `$6ADD` (32 bytes) |
| `tables/rhombus-columns.txt` | the order the phases drop the 40 columns in | numbers | RombColumnOrder `$6B74` (40 bytes) |
| `tables/rhombus-offsets.txt` | each phase's start column | numbers | RombPhaseOffsets `$6B9C` (9 bytes) |
| `tables/exit-sound.txt` | the bell: AY registers 0-13 | `Rn: value` | ExitSound `$6E64` (14 bytes) |
| `tables/randoms.txt` | the twinkles' first places | numbers | Randoms `$ADEC` (8 bytes) |
| `texts/menu-help.txt` | the three help lines | UTF-8 with `{AT y,x}` `{INK n}` controls | MenuHelp `$6AFD` (68 bytes) |
| `texts/no-files.txt` | NO EXE FILES ! | the same | NoFilesText `$6B41` (18 bytes) |
| `texts/player-text.txt` | the ASC compiler's credit in the player, never printed | the same | PlayerText `$C014` (63 bytes, src/music) |
| `tables/note-periods.txt` | the AY tone period of each of the player's 86 notes | one decimal period a line | PeriodTable `$C3CA` (172 bytes, src/music) |
| `basic/launch-lines.txt` | the BASIC's lines 1-3, line 1 the launch line the menu rewrites | BASIC listing (`tools/res_basic.py`) | LaunchLine `$5D3B` (64 bytes, src/basic) |
| `basic/line-ten.txt` | line 10 (the autostart line), the end mark and the autostart line number | the same | LineTen `$5DC6` (45 bytes, src/basic) |
| `music/disco.txt` | the ASC Sound Master module "Disco music" by Ant P | text (positions, patterns, samples, ornaments) | TuneHeader `$C478` (4379 bytes, src/music) |
| `spare/code-tail.bin` | the code piece's last bytes, not read | bytes | TwinkleSpare `$6FE0` (200 bytes) |
| `spare/graphics-tail.bin` | the graphics piece's last bytes, not read | bytes | GraphicsSpare `$ADF9` (7 bytes) |
| `spare/basic-tail.bin` | the BASIC sector after the program, not read | bytes | SectorTail `$5DF3` (72 bytes, src/basic) |
| `spare/music-tail.bin` | the music piece after the tune, not read | bytes | SectorTail `$D593` (109 bytes, src/music) |

Each folder's README.md gives the readers and the formats.

## What stays bytes in the `.ann`, and why

- `BootName` `$6B6B` (`t`, 9 bytes): the name and type IsBootFile compares against, part of the code's logic.
- Line 4's header and end (LineFour `$5D7B`, LineFourEnd `$5DC5`, 6 bytes): the REM frame around the loader's code,
  which is a code entry; the other lines are `basic/`. A variant with other lines keeps its whole sector as its own
  `basic.txt` (`tools/res_basic.py`).
- The player's header and working state in `src/music` (PlayerVectors, PlayerHeaderBytes, the channel records, the
  AY image, CurrentChannel, DelayCounter, PeriodPad): set or overwritten when the player runs, not data anyone edits.
