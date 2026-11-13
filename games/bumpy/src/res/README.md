# Resources

Every resource out of the code, in an editable format; `tools/res_formats.py build` turns them back into the bytes
the sources INCBIN, `tools/res_formats.py check` proves the round trip (43 editable files, 0 bad; the `.bin` files of
leftovers/ are bytes). kit/mkgame.py `--install` writes them from the images through `install()`. The parts: the game
(tape block 6, src/game) and the loading screen (block 4, src/screen).

| File | What | Format | Entry |
| --- | --- | --- | --- |
| `levels/levels.txt` | the 100 levels: cells (platforms, walls), start, exit, prizes, objects | text grids | LevelRecords `$8C3C` |
| `sprites/*.png` | the ball, objects, platforms, walls, exit, flames, steam, burst, bricks, side panels, logo, unused panel | 4-pen CPC PNG | BallPictures `$67E8`, ObjectPictures `$6CE8`, Platform1Pictures `$7788`, ... |
| `sprites/editor-font.png` | the CPC level editor's letters (unused) | mono PNG | EditorFont `$E21E` |
| `fonts/font.png` | the font, characters 32-127 (123-127 the HUD icons) | mono PNG | Font `$F5C9` |
| `screens/loading.png` | the loading screen | PNG colour cells | LoadingScreen `$4000` (src/screen) |
| `texts/*.txt` | the menu, players, hall of fame frame, the unused "Erase Una Vez" and editor texts | UTF-8 quoted | MenuText `$EFEF`, ... |
| `tables/*.csv`, `*.txt` | object inks, demo moves, level colours, cell and wall addresses, brick steps, control sets, hall of fame | CSV / records | ObjectInks `$C6F6`, DemoMoves `$D25A`, ... |
| `leftovers/*.bin` | bytes no routine reads: unused CPC pictures, the sound effects' parameter blocks, `$E0C4` | bytes | Unused8385 `$8385`, ... |
