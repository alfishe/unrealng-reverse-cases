# Sprites

Amstrad CPC mode-1 pictures as 4-pen PNGs: a byte is 4 pixels, pixel i's pen = bit 7-i + 2 x bit 3-i; index 0 black,
1 grey, 2 yellow, 3 white, 4 the grid between frames. The PNG text chunk `tx-cpc` keeps the width in bytes, the
height, the frame count and the frames a row. The Spectrum's blitters (DrawSprite `$E318`, XorSprite `$E3EE`, the
coloured `$E3E5`) show only the low nibble (pens 2 and 3 as ink, one Spectrum pixel a CPC pixel), XorBricks `$E4C4`
the high nibble; a picture w bytes wide is 4w pixels. Widths and heights come from the callers (SpriteWidth `$A9FE`
and B).

| File | Address | Bytes | Layout | Readers | What |
| --- | --- | ---: | --- | --- | --- |
| `sides.png` | SidePanels `$6398` | 768 | 2 x 192, 2 | DrawSides `$B488` | the play screen's left and right panels |
| `exit-sign.png` | ExitSign `$6698` | 112 | 8 x 7, 2 | DrawExitSign `$D08E` (unrun) | an EXIT sign |
| `ball.png` | BallPictures `$67E8` | 1280 | 4 x 10, 32 | the ball states via BallFramesRight/Left `$C4E2`/`$C502` | player 1's round ball and 15 rolling frames, then player 2's ($6A68) |
| `objects.png` | ObjectPictures `$6CE8` | 2240 | 4 x 14, 40 | TakeObject `$B958`, BuildLevelObject `$CFF4` | objects 1-40 (kind k at `$6CB0` + 56k) |
| `platform-1.png` ... `platform-5.png` | `$7788`, `$7900`, `$7A78`, `$7B62`, `$7BE2` | 376, 376, 234, 128, 376 | one column: rest (4 lines), two take-off pictures, three spring pictures | PlatDraw1-9, SpringPics `$C5D6`, TakeoffPics `$C64E` | platform types 1-5 (rows 4+10+10+7+9+7 for 8-wide, 4+8+8+6+7+6 for type 3, 4+6+6+5+6+5 for type 4) |
| `spikes.png` | SpikesPicture `$7D5A` | 42 | 6 x 7 | PlatDraw12 `$D1B2` | platform 12 |
| `crumble-8/6/4/2.png`, `crumble-bits.png` | `$7D84`, `$7DA4`, `$7DEC`, `$7E1C`, `$7E34` | 32, 72, 48, 24, 40 | 8x4; 6x4 x3; 4x4 x3; 2x4 x3; 2x5 x4 | the crumble steps `$C258-$C3BF` | a crumbling platform falling apart |
| `walls.png` | WallPictures `$7E5C` | 624 | 2 x 24, 13 | AnimateWalls `$BC30`, WallDraw1-4, the lock steps `$C492-$C4B1` | wall 4's 4 frames, locks 3/2/1, the flash, a lock opening (5) |
| `exit-mark.png`, `exit.png` | ExitMark `$80CC`, ExitFrames `$80D5` | 9, 120 | 1 x 9; 6 x 5, 4 | OpenExit `$BCB9`, AnimateExit `$BD21` | the exit |
| `fire.png` | FirePictures `$814D` | 90 | 6 x 5, 3 | AnimateFires `$BBCD`, PlatDraw8/9 | flames |
| `steam.png`, `steam-small.png` | SteamPictures `$81A7`, SteamSmall `$81E9` | 66, 12 | 6 x 11 (6x6, 6x3, 6x2 one under the other); 4 x 3 | the fire put-out steps `$C13E-$C185` | steam over a fire put out |
| `burst.png` | BurstPictures `$81F5` | 336 | 4 x 14, 6 | the burst, state 6 (`$B195-$B1C2`) | the ball bursting |
| `bricks.png` | BrickPicture `$8345` | 64 | 8 x 8 | DrawBricks `$D180` via XorBricks | one brick layer (high nibble) |
| `logo.png` | Logo `$E808` | 1080 | 18 x 60 | DrawLogo `$E7F7` | the menu's BUMPY logo |
| `panel.png` | PanelPicture `$D2B4` | 3600 | 18 x 200 | DrawPanelA/B `$CF0C`/`$CF1D` (unrun) | a CPC side panel the Spectrum never shows |
| `editor-font.png` | EditorFont `$E21E` | 130 | mono 8 x 5, 26 | none | the CPC level editor's letters A-Z |

BlankPicture `$6708` (80 zeros) stays in the source.
