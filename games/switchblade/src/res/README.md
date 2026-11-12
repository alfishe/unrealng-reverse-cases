# Resources

Every resource out of the code, in an editable format. `tools/res_formats.py build` turns them back into the bytes
the sources INCBIN, and `tools/res_formats.py check` proves the round trip (84 editable files, 0 bad; the 5 `.bin`
files of leftovers/ are bytes). `kit/mkgame.py --install` (`tools/mkasm_all.sh`) writes them from the images through
`install()`.

The parts:

- the game (block 5, `src/game/game.ann`): every folder;
- bank 4 (block 6, 128K only, `src/bank4/bank4.ann`): music/, texts/story.txt, graphics/story-*;
- stage 2 (`src/stage2/stage2.ann`): graphics/loader-*;
- the BASIC loader (`src/tape/basic.ann`): texts/tape-error.txt.

| Folder | What | Formats | Entries |
| --- | --- | --- | --- |
| [`rooms/`](rooms/README.md) | the 127 rooms, the map, the room builder's tables: outline shapes, tile strings, bars, the horizon, solid and ledge tiles, pickup tiles | text (rooms.txt, map.txt), CSV, hex lines | Room1 `$A928`-Room127, MapColumns `$7048`, RoomPatternStarts `$7300`, StructureRecords `$7400`, ... |
| [`graphics/`](graphics/README.md) | the tiles, the 23 sprite sets (Hiro, the enemies, the giants, the title pieces), the font, the end picture, the intro and story glyphs, the loader's logo and scroll, attribute blocks, the panel | PNG (3-bit column sheets, 1-bit rows); hex lines | Tiles `$D104`, EnemyFrames `$E154`, ..., Font `$7BE5`, HavokPicture `$7F7D`, IntroGlyphs `$6313`, StoryFont `$D991` (bank 4), Logo `$622B` (stage 2) |
| [`texts/`](texts/README.md) | the print records: the intro and story pages, the high-score table and its strings, the menus, the panel lines, the end text | text and picture records | IntroScript `$5E4D`, CursorEraseText `$80EB`-EndText `$82E0`, StoryEyesClosed `$D4CB` (bank 4), ... |
| [`tables/`](tables/README.md) | the page-tail tables (scores, items, weapons, touch zones, sprite sets, actor templates, cell colours), the kind templates, the 48K effects, the gates, the title scene, the actor scripts, the packer phases | CSV; hex lines | PageTailTemplate `$6B5C`-CellColoursTemplate `$703F`, KindTemplates `$7200`, EffectTable `$8683`, ActorScripts `$76EA`, ... |
| [`music/`](music/README.md) | bank 4's three tunes (patterns and order lists), arpeggios, instruments, the 128K effects, the note periods | text (tunes.txt); CSV | Patterns `$C4B8`-OrderLists `$CD03`, Arpeggios `$CE8C`, Instruments `$CED4`, Effects `$CF60`, NoteTable `$D016` |
| [`leftovers/`](leftovers/README.md) | five stretches of zeros that no code reads | bytes | ControlGap `$6B4D`, Leftover72FE `$72FE`, Spare73F9 `$73F9`, RoomDataPad `$D0F9`, PanelEnd `$FFFF` |

Each folder's README.md gives every file's address, size, format and readers (the routine names of the `.ann`).

## The formats

All of them are in `tools/res_formats.py`: see its docstring, and the comment lines each editable file starts with.

- **3-bit column pictures** (PNG): the game's own picture format (UnpackGroups `$8BC8`).
  - The picture is cut into 3-pixel units, one 3-bit value each (bit 2 the left pixel, 1 ink). Eight values pack
    into three bytes, column by column.
  - The PNG is a sheet of frames on a grey grid. The palette is 0 paper (black), 1 ink (white) and 2 the grid.
  - The text chunk `sw-col3` holds the units across, the rows and the frame count.
- **1-bit rows** (PNG): bytes of 8 pixels, in frames `wb` bytes wide and `h` rows tall. Used for the fonts, the
  glyphs, the end picture and the loader's pictures. The text chunk `sw-rows` holds the layout. A file that starts
  or ends inside a frame has grey rows there.
- **Text records** (`.txt`):
  - a print record of PrintString `$837B` is a `text Y X S1 S2` line, then one quoted line a text line;
  - a picture record of PrintGlyphs `$61E5` or PrintStoryString `$D863` is a `picture Y X` line, then one line of hex
    glyph numbers a row;
  - `raw "..."` holds any other bytes;
  - in quotes, `\xNN` is a byte outside the printable range.
- **CSV tables**: a header line, then one record a line. Numbers are decimal or `$hex`. A column whose name starts
  with `_` is a note and is not read back.
- **Hex lines** (`.txt`): one record or list a line. `$ADDR:` at a line's start, and `#` lines, are comments.
- **rooms/rooms.txt, rooms/map.txt, music/tunes.txt**: decoded records, described in their folders' READMEs.

Every resource is INCBINed at fixed offsets, so an edit must keep each file's size. `check` does not test the size;
the build's `cmp` does.

## Labels inside resources

A label inside a resource splits its INCBIN there (kit/mkgame.py), so every operand that points into a resource still
resolves. These labels split their resource's INCBIN:

| File | Labels inside |
| --- | --- |
| rooms/rooms.bin | Room2 ... Room127 (RoomDataPointers `$7102` holds them as DEFW) |
| rooms/map.bin, solid-tiles.bin, decor-tiles.bin | MapRowCounts, MapRowStarts; LedgeTiles, TopTiles; ShapeTilesB |
| rooms/bars-1.bin, bars-2.bin | StructureSetB, StructureSetC, ComposeDest `$74BA` (a variable word); StructureSetE, StructureSetF |
| texts/intro.bin | the run-time names (`@var`) SetTune `$5FC0`, HavokRoomLeave, HavokRoomEnter, SizeClasses `$6082` |
| graphics/intro-glyphs-1.bin, intro-glyphs-2.bin | the run-time names of the actor pages, the globals and the room planes: WeaponTemplate ... ShowMessage (Vitality `$6642` ... StatusLine, WeaponIcon); TitleColours, EnemySlots, HiroFallScript, BoxClip, MapRow, MapColumn, Strike, FireHeld |
| texts/control-menu.bin | ItemCount, EnemyCount, EnemyListPtr, ZoneCount, ZoneRecords (`$6ADC-$6AEC`, run-time variables in plane `$6A`) |
| tables/items.bin, weapons.bin, sprite-sets.bin, actor-templates.bin | PageTail5E, RoomAbove `$6BDC` ... CellProperty `$6BE3`; PageTail5F; HavokStashB `$6D00`; PageTail62-65, TakenItems, RevealedZones, HavokStashA, GoneEnemies, OutlineMask `$6F00` |
| tables/gates.bin | GateClosed, GateX, GateSide |
| tables/scripts-7a.bin | StrikeScript1 ... Script911A, MessageNumber `$7B63` (a variable), SpawnTriples, SpawnedScript, Script9115 |
| graphics/font.bin, panel-meter.bin, letter-attrs.bin, intro-attrs.bin | MeterGlyphs `$7F0D`; MeterStrip, MeterPartial, MeterEmpty; ExtraBonusLit; IntroAttrsB, IntroAttrsC |
| texts/hiscore-texts.bin, hiscores.bin, strings.bin, panel.bin | HiScoreHeading, HiScoreRankText; HiScoreEntries; EffectsIconText ... EndText, NameEntryLetters, FirebladeGlyphs; StatusLineInit |
| music/tunes.bin (bank 4) | Pattern01-Pattern44, PatternAddrLo, PatternAddrHi, TuneTable, Tune0OrderA-Tune2OrderC (TuneTable's DEFW labels are checked by ASSERT lines) |
| texts/story.bin, graphics/story-attrs.bin (bank 4) | StoryText1 ... StoryText6; StoryAttrs2, PortraitAttrs |

## What stays bytes in the `.ann`, and why

These data entries have no `@res` line:

- **Code kept as data rows**:
  - SetTuneCode `$6C96`, TitleWhiteRowsCode `$6FB8` and PageTail66 `$6FCA`: code that is copied into the page tails
    and run there;
  - ControlRecords `$6B0A`: input-code patches;
  - GlyphBytesAsCode `$66CD`: a `c` entry of intro glyph bytes, which the recordings count as run (it splits
    intro-glyphs-1 from intro-glyphs-2);
  - BlitRowsLdi, PackUnitsStop1 and PackUnitsStop2: code bytes.
- **Variables**:
  - GlobalsInit `$5C00`: the globals' start values;
  - DrawColumnPos `$732A`, TitleSceneIndex `$76D0` and MessageRequest `$79FF`;
  - the sound state: SoundVars and EffectState;
  - bank 4's player state: MusicState, SeqChannelA, SlotTables, Drum*, AyMixer, AyChannelA and NoisePeriod.
- **Address tables** (`w`), kept as DEFW so they follow the code: RoomDataPointers `$7102`, RoomCodeHandlers `$73C7`,
  ActorKindHandlers `$73E5` and RoomCodeHandlersB `$75EF`.
- **Zero space written before use**: SpriteSetsTail `$6D4E`, ReadInputSpace `$8530` and Im2Space `$FDFD`.
- **The loaders' own data**: BasicLine0 and the boot's HookBytes.

## Figures

`tools/fig_rooms.py` draws every room, and the whole map, from src/res alone. It reads rooms/, graphics/tiles.png,
enemies.png and giants.png, and tables/cell-colours.csv, plus the 48K ROM (rooms/README.md).
