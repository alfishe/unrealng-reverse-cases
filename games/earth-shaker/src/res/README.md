# Resources

Every resource out of the code, in an editable format; `tools/res_formats.py build` turns them back into the bytes
the source INCBINs (and the two `.inc` files it INCLUDEs), `tools/res_formats.py check` proves the round trip
(47 editable files, 0 bad). kit/mkgame.py `--install` writes them from the image through `install()`.

| File | What | Format | Entry |
| --- | --- | --- | --- |
| `caves/caves.txt` | the 32 caves: 14 parameters by name, 20 rows of 30 cells | text grid (include: graphic words by name) | CaveData `$C000` |
| `graphics/cells-a.png`, `cells-b.png` | the cell graphics, slots 0-20 and 22-77 | PNG tiles (Spectrum colours) | CellGraphics `$9B08`, CellGraphics2 `$9E20` |
| `graphics/extra-a.png` - `extra-d.png` | the extra wall and earth graphics the caves pick | PNG tiles | ExtraGraphics `$ED28`, ExtraGraphic2 `$EE00`, ExtraGraphic3 `$EF00`, ExtraGraphic4 `$FBA0` |
| `graphics/blank.png`, `empty-frames.png` | the empty cell; the falling-earth caves' four empty frames | PNG tiles | BlankGraphic `$AA72`, EmptyFrames `$FAE0` |
| `graphics/font.png` | the font, characters `$20-$7F` | PNG glyph sheet | Font `$BD00` |
| `graphics/map-glyphs.png`, `map-frame.png` | the map screen's cell glyphs and frame | PNG glyph sheets | MapGlyphs `$9A00`, MapFrameGlyphs `$E9C0` |
| `graphics/logo.png`, `logo-attrs.txt` | the title logo, pixels and attributes | PNG 256 x 64; hex | LogoPixels `$B300`, LogoAttrs `$FC00` |
| `graphics/teleport-frames.txt` | the teleport flash's four attribute screens | hex | TeleportFrames `$7300` |
| `music/*.txt` | the eleven tunes, the note periods, the cave-tune table | text (cave-tunes: include) | TitleTune `$AD00`, NotePeriods `$BC00`, CaveTunes `$EE24`, ... |
| `tables/keys.csv`, `keyboard-code.csv`, `kempston-code.csv` | the key table and the two control code sets | CSV | KeyTable `$A900`, KeyboardCode `$EB15`, KempstonCode `$EAC4` |
| `tables/hiscores.csv` | the high-score defaults | CSV | HiScoreTable `$FD14` |
| `tables/map-attrs.csv`, `bar-attrs.txt` | the map's cell colours, the time bar's colours | CSV; hex | MapAttrs `$9A80`, BarAttrs `$BC92` |
| `texts/*.txt` | the scroller, menu, HUD, prompts, cave names (the passwords), win and game-over texts, the 1988 credits | quoted text | ScrollerText `$6D42`, CaveNames `$9700`, ... |
| `leftovers/*.bin` | twelve stretches no code reads | bytes | see leftovers/README.md |

Each folder's README.md gives the addresses, sizes, readers and formats. `tools/fig_caves.py` draws the caves from
`caves/caves.txt` and the cell PNGs (docs/img/maps, docs/img/sprites/cells-cave01.png).
