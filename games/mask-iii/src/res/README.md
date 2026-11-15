# Resources

Every resource out of the code, in an editable format. `tools/res_formats.py build` turns the sources back into the
bytes the source INCBINs (build/res/*.bin), `tools/res_formats.py check` proves each round trip, and
`tools/build.sh` proves the whole tape identical. Each folder's README lists its files and their entries.

| Folder | What | Format | Part |
| --- | --- | --- | --- |
| `charsets/` | the four zones' 256 characters and attributes | PNG + CSV | game |
| `rooms/` | the 16 room maps | text grids | game |
| `blocks/` | the 192 blocks of 4 x 4 characters | text | game |
| `sprites/` | Matt, the enemies, icons, digits | PNG | game |
| `font/` | the 5-row font | PNG | game |
| `screens/` | the loading screen, the menu pictures, the play panel | PNG + CSV | screen, game |
| `texts/` | the menu, the messages, the mask names, the passwords | UTF-8 text | game |
| `tables/` | the room table, the pick-ups, the effects, the enemy templates | CSV | game |
| `music/` | the AY tunes and instruments | text, bytes | music |
| `leftovers/` | bytes the game never reads | bytes | game |
