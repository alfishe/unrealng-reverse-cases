# Graphics

A cell graphic is 36 bytes: the attributes of its 2 x 2 character cells (top left, top right, bottom right, bottom
left), then 32 pixel bytes, two a pixel line, left byte then right on even lines and right then left on odd ones
(DrawCell `$8F60` draws the zigzag). The cell PNGs show each graphic as a 16 x 16 tile, 8 a row, a grey line between
tiles; the palette holds the 64 Spectrum attribute colours (index = flash x 32 + ink x 16 + bright x 8 + colour) and
grey, so each pixel says whether it is ink or paper and the bytes come back exactly. The attribute of a quarter that
is all paper (or all ink) cannot be seen: the PNG chunk `es-cells` keeps it. The glyph sheets are indexed PNGs (0
paper, 1 ink, 2 the grid), the chunk `es-sheet` holds the glyph count and the glyphs a row.

| File | Address | Bytes | Readers | What |
| --- | --- | ---: | --- | --- |
| `cells-a.png` | `$9B08-$9DFB` | 756 | CellGraphicsTable `$8000` words, DrawCell `$8F60`, CaveSetup `$9313` (colours), AnimateCells `$900B`, DrawPass `$8D46` (gem ink), DeathView `$903F`, ExitFlash `$905B`, WinScreen `$A61C` | slots 0-20: GfxExit (cell 1), GfxBoulder (2), GfxEarth (6), GfxGem (7), GfxPlayerRight (3, four frames), GfxPlayerLeft (4, four frames), GfxWall1-GfxWall6 (the caves' walls), GfxSpare (slot 18, never read), GfxDeathRight, GfxDeathLeft (slot 20, never drawn in a recording) |
| `cells-b.png` | `$9E20-$A5FF` | 2016 | AnimateTable `$90B2`, EarthAnim `$9DFC`, CaveSetupAll `$A600` (the dissolve frames' colour), the table words | slots 22-77: the switch (cell `$B`), fire (`$F`, 4 frames), teleporter (`$D`, 12), bubble (`$E`, 4), dissolve (`$15-$1B`, 7), force field (9, 8), anti-gravity arrow (`$A`, 4), GfxFallingEarth `$A450` (4, the falling earth of caves 13, 17, 22, 24, 26), GfxJellyBean (8, 4), GfxBurst (`$10-$14`, 4) |
| `extra-a.png` | `$ED28-$EDDB` | 180 | CaveSetup through the caves' earth_graphic / wall_graphic | ExtraGraphics (earth and wall of cave 20), GfxExtraWall2 (wall of cave 4), GfxExtraWall3 (18), GfxExtraWall4 (7), GfxExtraWall5 (10, 26) |
| `extra-b.png` | `$EE00-$EE23` | 36 | the same | ExtraGraphic2: the wall of caves 24 and 28 |
| `extra-c.png` | `$EF00-$EF23` | 36 | the same | ExtraGraphic3: the wall of cave 2 |
| `extra-d.png` | `$FBA0-$FBE7` | 72 | the same | ExtraGraphic4 (the earth of cave 15), GfxExtraWall9 (the wall of cave 16) |
| `blank.png` | `$AA72-$AA95` | 36 | CellGraphicsTable word 0, SetEarthFalls `$FB81`, ClearHiScoreArea `$B2C9` | BlankGraphic: 36 zeros, the empty cell |
| `empty-frames.png` | `$FAE0-$FB6F` | 144 | EarthAnimStep `$FB70` | EmptyFrames: four frames of the empty cell in the falling-earth caves, all zeros (a hook with no picture) |
| `font.png` | `$BD00-$BFFF` | 768 | PrintText `$834F` (`Font-256`), PrintDigits `$832A`, AntiGravStartScan `$A7A0`, AntiGravPass `$A7CD` | Font: characters `$20-$7F`, 8 bytes each, 16 a row; DigitGlyphs `$BD80`, IconGlyphs `$BF08`, AntiGravIcon `$BF18`, AntiGravIconOff `$BF20`; codes `$68-$7F` (FontUnused `$BF40`) are never printed |
| `map-glyphs.png` | `$9A00-$9A7F` | 128 | MapCellGlyph `$E9AE` (D = `$9A`, the operand inside DrawMapCells' overlapped bytes `$805E`) | MapGlyphs: the map screen's 8 x 8 glyph of each cell code 0-15 |
| `map-frame.png` | `$E9C0-$E9FF` | 64 | DrawMapFrame `$EA00` | MapFrameGlyphs: the map frame's 8 glyphs, 8 a row |
| `logo.png` | `$B300-$BAFF` | 2048 | WipeInLogo `$8979` (`(LogoPixels-Screen)/256` added to the screen address) | LogoPixels: the title logo laid out as the screen's top third, shown as a 256 x 64 picture (chunk `es-logo`) |
| `logo-attrs.txt` | `$FC00-$FCFF` | 256 | ShowLogo `$9091` | LogoAttrs: the logo's attributes, 8 rows of 32, hex |
| `teleport-frames.txt` | `$7300-$7EFF` | 3072 | TeleportFlashOut `$9230`, TeleportFlashIn `$924F` | TeleportFrames: four attribute screens of 768 bytes copied to `$5800` in turn, hex, 32 a line |

Per cave, CaveSetup `$9313` points table words 6 and 5 at the cave's earth and wall graphics and writes four colours
into GfxExit, GfxBoulder, GfxWall1 and GfxEarth (caves/README.md). Cave 30's earth is GfxBoulder. The cell table
`$8000` itself stays in the source (a `w` entry of DEFW labels): its words are names.
