# Graphics

## The 3-bit column pictures

These are the tiles and the 23 sprite sets: set n of the table PageTail60 `$6CD6` (SizeClasses `$6082` at run time,
tables/sprite-sets.csv). Pictures are cut into 3-pixel units, each one 3-bit value (bit 2 the left pixel, 1 ink);
eight values pack into three bytes, MSB first. A frame is its columns one after the other, left first, each `rows`
values top first, so it takes `units x rows x 3 / 8` bytes. UnpackGroups `$8BC8` unpacks them; FrameRecord `$8EA3`
finds tile n at `$D104` + 24 (n - 1). The room cells are drawn by RedrawCell `$8867` and ComposeTileWith `$89D9`, the
outlined ones by MaskedColumn `$8C0F`. The actors are drawn with the record InitActor `$A65D` copies from the set,
mirrored by MirroredColumn `$8C51`.

The PNG shows the frames in a grid on grey, one pixel apart, frame 0 at the top left. It is an indexed PNG: 0 paper,
1 ink, 2 the grid. The text chunk `sw-col3` gives the units across, the rows, the frames and the frames a row of the
sheet. Edit the pixels, keep the grid.

| File | Address | Bytes | Units x rows (pixels) | Frames | Set | What |
| --- | --- | ---: | --- | ---: | ---: | --- |
| `tiles.png` | Tiles `$D104-$E153` | 4176 | 4 x 16 (12 x 16) | 174 | 0 | the room tiles, tile n = frame n - 1 |
| `enemies.png` | EnemyFrames `$E154-$E5BB` | 1128 | 4 x 16 | 47 | 1 | the small enemies and hazards |
| `giants.png` | GiantFrames `$E5BC-$E97B` | 960 | 8 x 32 (24 x 32) | 10 | 2 | the giants |
| `hiro.png` | HiroFrames `$E97C-$F30B` | 2448 | 4 x 32 | 51 | 3 | Hiro |
| `hiro-15.png` | HiroFrames15 `$F30C-$F4AF` | 420 | 5 x 32 | 7 | 4 | Hiro's wider poses |
| `hiro-18.png` | HiroFrames18 `$F4B0-$F65F` | 432 | 6 x 32 | 6 | 5 | Hiro's widest poses |
| `hiro-21.png` | HiroFrames21 `$F660-$F707` | 168 | 7 x 32 | 2 | 6 | two 21-pixel poses |
| `sparks.png` | SparkFrames `$F708-$F78B` | 132 | 2 x 8 | 22 | 7 | sparks and shots |
| `shots.png` | ShotFrames `$F78C-$F7E5` | 90 | 3 x 8 | 10 | 8 | shots |
| `scores.png` | ScoreFrames `$F7E6-$F87B` | 150 | 5 x 8 | 10 | 9 | the score values (tables/score-table.csv) |
| `messages.png` | MessageFrames `$F87C-$F953` | 216 | 9 x 16 | 4 | 10 | the banner messages |
| `gremlin-logo.png` | GremlinLogo `$F954-$F995` | 66 | 11 x 16 | 1 | 11 | the GREMLIN logo |
| `title-12.png` ... `title-23.png` | TitlePiece12 `$F996` ... TitlePiece23 `$FCF0-$FD97` | 24, 60, 36, 150, 54, 144, 90, 24, 144, 120, 12, 168 | 2 x 32, 2 x 40, 2 x 48, 5 x 40, 6 x 24, 6 x 32, 6 x 40, 8 x 8, 8 x 24, 8 x 40, 4 x 8, 14 x 32 | 1, 2, 1, 2, 1, 2, 1, 1, 2, 1, 1, 1 | 12-23 | the pieces of the SWITCHBLADE title, flown in by TitleSequence `$A73E` (LoadTitlePieces `$A7D7`) |

## 1-bit rows

Plain bytes of 8 pixels, MSB left. The PNG has frames `wb` bytes wide and `h` rows tall on a grey grid (palette 0
paper, 1 ink, 2 grey). The text chunk `sw-rows` gives `wb`, `h`, the frames a row, `lead` (the grey rows before the
first byte), the byte count and the number of the first glyph.

| File | Address | Bytes | Frames | Readers | What |
| --- | --- | ---: | --- | --- | --- |
| `font.png` | Font `$7BE5-$7F1C` (MeterGlyphs `$7F0D`) | 824 | 103 glyphs of 8 x 8, codes `$20-$86` | PrintString `$837B` (`LD BC,Font`), PrintStringTall `$836E` | the game font: letters, digits, the box frame, the panel's glyphs |
| `havok.png` | HavokPicture `$7F7D-$80EA` | 366 | one 48 x 61 picture | DrawHavok `$8769`, ShiftHavokGraphic `$87A6` | the end picture of Havok |
| `intro-glyphs-1.png` | IntroGlyphs `$6313-$66CC` | 954 | glyphs 1-119 and the first 2 rows of glyph 120 | PrintGlyphs `$61E5` through IntroPicture `$5DE6` (Intro48 `$5D4F`) | the 48K intro's picture glyphs |
| `intro-glyphs-2.png` | CellColours `$66F7-$6A7A` | 900 | from row 4 of glyph 125 to glyph 237 | PrintGlyphs `$61E5` | the rest of them. The 42 bytes `$66CD-$66F6` between the two files stay in the `.ann` as the `c` entry GlyphBytesAsCode (the recordings count `$66CD` as run: the page tail's code at run time). graphics/story-font.png holds the whole set |
| `story-font.png` | StoryFont `$D991-$E0F8` (bank 4) | 1896 | 237 glyphs of 8 x 8, codes 1-`$ED` | PrintStoryString `$D863` (StoryPages `$D3D0`) | the 128K story's picture glyphs, the same 237 glyphs as IntroGlyphs |
| `loader-logo.png` | Logo `$622B-$670A` (stage 2) | 1248 | one 208 x 48 picture | Stage2Title `$61B2` through Blit `$6200` | the SWITCHBLADE logo of the loading screen |
| `loader-scroll.png` | ScrollText `$670B-$68A7` (stage 2) | 413 | one 472 x 7 strip | Stage2Title `$61B2`, ScrollShow `$61F5` | "COPYRIGHT GREMLIN GRAPHICS 1991" ... "LOADING" in pixels, scrolled in place |

## Hex lines

| File | Address | Bytes | Readers | What |
| --- | --- | ---: | --- | --- |
| `fireblade-icons.txt` | FirebladeIcons `$7F1D-$7F7C` | 96 | PanelFragments `$FF3C` | 16 panel pictures of the growing Fireblade, six font codes each, copied into FirebladePanelText |
| `intro-attrs.txt` | IntroAttrsA `$6225`, IntroAttrsB `$6234`, IntroAttrsC `$6243` (to `$6312`) | 238 | CopyAttrBlock `$6212` (Intro48 `$5D4F`) | the intro's attribute blocks: 5 x 3, 5 x 3, 13 x 16 |
| `story-attrs.txt` | StoryAttrs1 `$D8A3`, StoryAttrs2 `$D8B2`, PortraitAttrs `$D8C1` (to `$D990`, bank 4) | 238 | CopyAttrBlock `$D890` (StoryPages `$D3D0`) | the same blocks for the 128K story |
| `panel-meter.txt` | MeterGradient `$FFB7` (MeterStrip `$FFBB`, MeterPartial `$FFC2`, MeterEmpty `$FFC3`, to `$FFCA`) | 20 | DrawMeter `$FF7C` (PanelMeters `$FF64`) | the energy and charge meters: the partial bytes, 7 full, the partial, 8 empty |
| `panel-attrs.txt` | PanelAttrs `$FFCB-$FFEA` | 32 | PanelAttrsRoom `$FFEB` | the panel's attribute row at `$5AE0` |
| `letter-attrs.txt` | ExtraBonusUnlit `$5C38`, ExtraBonusLit `$5C3D` (to `$5C41`) | 10 | the letter check `$999F-$99CE` | the attributes of the unlit and lit EXTRA / BONUS letters |
