# Resources

Every resource out of the code, in an editable format; `tools/res_formats.py build` turns them back into the bytes
the source INCBINs, `tools/res_formats.py check` proves the round trip.

| File | What | Format | Entry |
| --- | --- | --- | --- |
| `graphics/charset0.png`, `charset1.png` | the two char sets (256 chars and their attributes each): levels 1-2, levels 3-4 | PNG in colours, a grid | CharSet0 + CharAttr0, CharSet1 + CharAttr1 |
| `graphics/font.png` | the font's 43 glyphs | PNG | Font |
| `levels/levels.txt` | the zones' maps, zone records, exits and objects | text | Maps, Zones, Exits, Objects (module `leveldata`) |
| `levels/tiles.txt` | the 256 tiles of 4 x 4 chars | text | Tiles |
| `levels/leveltable.txt` | the level table: each level's intro text, Rick's start, its first zone (5 records) | text, the words by name (`@res ... include`) | LevelTable |
| `levels/charprops.txt` | the char properties of the two char sets: ladder, deadly, platform, spring, wall, floor | text | CharPropsSet0, CharPropsSet1 |
| `levels/kinds.txt` | the 72 object kinds, their animations and movement scripts | text | ObjectKinds, the anims and scripts |
| `sprites/frames.png` | the 54 sprite frames, mask and pixels | PNG, four indices | SpriteFrames |
| `sprites/copied.png` | the two frames Start copies to `$6A80` and `$7080` | PNG, four indices | Kind16Frame, Kind19Frame (module `loader`) |
| `texts/*.txt` | the ten texts: the level intros, the ending, the menu, GAME OVER | text | the `*Text` entries |
| `screens/loading.png` | the loading screen (`screens/loading.scr`, tape group 1) | PNG in colours | src/tape/tape.txt |
| `music/music.txt` | the AY player's patterns, tunes, order lists, instruments and effects | text | the music part's tables (src/music) |
| `music/periods.txt` | the AY player's 85 tone periods | text | PeriodTable (src/music) |
| `loader/keypage.bin`, `lastblock.bin` | tape group 1's key page and decoy last block | bytes (see `loader/README.md`) | src/tape/tape.txt |

Each folder's README.md has the addresses, the format and the readers.

Built, not kept here (case.json `built`; tools/build.sh copies them to `build/res`): `loader/stage2.bin`
(src/loader/stage2.asm) and `music/music.bin` (src/music/music.asm), which the game's module `loader` INCBINs at
`$5D00` and `$5E00`.

## What stays bytes in the `.ann`, and why

- The 128K ROM's and the loader's leftovers below `$5E00` (RomPagingRoutines, the system variables, BasicLeft,
  LoaderStack) and the BASIC session residue at `$FF1E-$FFED`: what the load leaves, not the game's data.
- The variables and work space (counters, Score, ObjectTable, RickVars, the AY channel and track records, the
  stack): their load values are zeros or the state at the entry, nothing a designer edits.
- The score awards `$A9C5-$A9E7` (Award1 ... LevelBonus): six five-digit numbers, four of them never read; kept as
  bytes beside AddScore, which takes their addresses.
- The small code tables: ObjectHandlers `$EC47` (routine addresses, written by name), FuseFrames `$ECF2`,
  EnemyWalkFrames `$F174`, WalkFrames `$FD6D` (sprite frame addresses by name), CycleColours `$AB3D` and
  PlainColours `$AB45` (eight and one attribute bytes of the menu highlight): words that are labels read better in
  the source than in a text.

