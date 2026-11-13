# Resources

Every resource out of the code, in an editable format; `tools/res_formats.py build` turns them back into the bytes
the sources INCBIN, `tools/res_formats.py check` proves the round trip (62 editable files, 0 bad). kit/mkgame.py
`--install` writes them from the images (`install()` for the game, the music and the screen, `install_level1` ...
`install_level5` for the level parts). The parts: game (side A block 6, `$7080-$A7FF`), music (block 6's first 4224
bytes, run in RAM 1 at `$C000`), screen (block 5), levels 1-5 (side B, 21 760 bytes at `$A800`).

| File | What | Format | Entry |
| --- | --- | --- | --- |
| `graphics/glyphs.png` | the 40 glyphs of the HUD and the texts: 0-9, bolt, detonator, life, A-Z, blank | PNG, 10 a row | Glyphs `$7080` |
| `screens/loading.png` | the loading screen | PNG screen (colour) | src/screen, side A block 5 at `$4000` |
| `texts/*.txt` | the control menu, the level menu, GAME OVER, the tape prompts, both endings | UTF-8, digits as shown, `{XX}` for bytes with no glyph | ControlMenuText `$8159`, LevelMenuText `$7FC7`, GameOverText `$7EC8`, TapeTexts `$843A`, CongratulationsText `$87A0`, FatGuyEndText `$883D` |
| `tables/level-starts.csv`, `section-counts.csv` | Rick's start in each level; the sections of each level | CSV | LevelStarts `$7C8F`, SectionCounts `$8374` |
| `tables/points.csv` | the score constants 50 ... 100 000 | CSV, six digits | Points50 `$7EF3` ... Points100000 `$7F11` |
| `tables/explosion-frames.csv`, `rick-walk-frames.csv` | the blast's and Rick's walk and crawl sprites | CSV (sprite numbers) | ExplosionFrames `$93C0`, WalkFrames `$9AA9` |
| `tables/beeper-effects.txt` | the eleven 48K beeper effects | a line an effect | BeeperEffects `$7B08` |
| `tables/periods.csv` | the AY tone periods of 85 semitones | CSV | Periods `$C672` (RAM 1) |
| `tunes/tunes.txt`, `patterns.txt` | the 11 tunes' order lists and the 54 patterns | text (notes by name) | TuneTable `$C2C0`, OrderLists `$C302`, Patterns `$C000`, PatternAddrLow/High `$C444`/`$C47A` |
| `tunes/instruments.csv`, `effects.csv`, `ornaments.csv` | the 7 instruments, the 28 sound effects, the 2 ornaments | CSV | Instruments `$C4C0`, Effects `$C506`, Ornaments `$C4B0` |
| `levels/levelN/level/cell-flags.csv`, `cells.png`, `blocks.txt` | each level's 256 cells (flags, graphics, attributes) and 256 blocks of 4 x 4 cells | CSV; PNG colour cells; text | CellFlags `$A800`, CellGraphics `$A900`, CellAttrs `$B100`, Blocks `$B200` |
| `levels/levelN/level/maps.txt`, `sections.txt` | each level's maps, its sections and their exits, objects, traps and enemies | text grids; text | the maps' base and SectionTable (LevelHeader `$C200`) |
| `levels/levelN/level/kinds.txt`, `frame-map.csv` | the trap and pickup kinds, their paths and animations; animation frame to sprite | text; CSV | KindTable, TrapAnims, TrapPaths, KindRecords; SpriteFrameMap `$C20E` |
| `levels/levelN/level/sprites.png` | each level's sprites (0-26 common: Rick, bullet, detonator, blast, boxes) | PNG sheet, 24 x 21 | Sprites `$C26D` |
| `levels/level5/level/fat-guy.txt`, `fat-guy-path.txt` | the Fat Guy's five parts, their flight after the kill, his path | text | FatGuyParts `$F83C`, FatGuyPath `$FAF4` |

Each folder's README.md gives the addresses, sizes, readers and formats. `tools/fig_rooms.py OUT` draws every section
and each level's map from levels/ (with tables/section-counts.csv).

## What stays bytes in the `.ann`, and why

Data no one edits as content stays as named `b` / `w` entries: the game's variables and work tables (the object
records `$7B8F` / `$7C20` are written over the entry code), the IM 2 handler's debris `$7C5C`, the 204 `$C9` bytes
after LoadError `$852E`, the mirror table built at run time, the music player's state and the source-text leftovers
in its variables (src/music), the loader's code (src/loader), and in the levels the unread leftovers listed in
levels/README.md.
