# tables

| File | Address | Size | Format | Readers |
| --- | --- | --- | --- | --- |
| `panels.csv` | PanelP1Sprites `$6C9E-$6D50` | 179 | the sprite lists PanelP1Sprites, PanelP2Sprites, HudSprites, LoadIntroSprites and the box lists LoadIntroBoxes, PanelP2Boxes, PanelP1Boxes, HudBoxes | SpriteList (`$6C17`), AttrBoxes (from PanelP1, PanelP2, ShowHud, LoadIntro) |
| `credits.csv` | TrailIntroBoxes `$6ED7-$6F0D` | 55 | the box lists TrailIntroBoxes, CreditBoxes, the sprite lists CreditSprites1, CreditSprites2, then HiScorePage `$6F0D` (one byte) | TrailIntro, Credits, HiScoreScreen |
| `menus.csv` | MenuDefs `$702A-$70A9` | 128 | the eight menus | MenuBox, MenuDraw, MenuDispatch |
| `trailinks.txt` | TrailInks `$79D4-$79D9` | 6 | the play window's attribute for trails 1-6 | `$79AF` (SelectTrail) |
| `tumbleoffsets.txt` | TumbleOffsets `$DC0D-$DC12` | 6 | the tumbling ATV's height offsets | AtvY (`$DC25`) |
| `ridepose.txt` | RidePoses `$DEEC-$DF17` | 44 | the mounted rider's sprite for each ATV frame | `$DEB7` |
| `riderjump.txt` | RiderJumpTable `$E312-$E31E` | 13 | the rider's jump steps, then FallSteps `$E319` (the ATV's fall per pass by VSpeed: 0, 1, 2, 4, 6, 6) | JumpControl (`$E408`, `$E448`); FallSteps at `$E5DC`, `$E609`, `$E9DE`, `$EAB9` |
| `wheeloffsets.txt` | WheelOffsets `$E61B-$E630` | 22 | the wheels' x and y offsets for each ATV frame from `$38` | AtvY (`$DC56`), `$E700` |
| `slopeframes.txt` | SlopeFrames `$E797-$E7BA` | 36 | the frame offset for each line of slope (0-`$14`) | AtvSlope (`$E777`), `$E7DC` |
| `slopetable2.txt` | SlopeTable2 `$E7EF-$E7FA` | 12 | multiples of 3 | none (a leftover) |
| `tumbleframes.txt` | TumbleFrames `$E86C-$E89B` | 48 | the tumble's frames (`$7D-$87`), then TumbleHeights `$E884` | Tumble (`$E8F0`, `$E8F8`) |

**Lists** (`panels.csv`, `credits.csv`): a row an item, `list,x,y,x2,y2,sprite,attr,bytes,shows`. A sprite item has x, y
and the game sprite (3 bytes); a box item has x1, y1, x2, y2 and the attribute (5 bytes); each list ends with `$FF`,
written by the build where the next list's name starts. A `bytes` row holds bytes as they are (HiScorePage).
`shows` names a game sprite of the panels' and the HUD's lists (SPEED, FUEL, clock, max, the panel edges), for the
reader; the build does not read it. LoadIntroSprites and the credits' lists draw menu pictures (MenuSpriteAt,
PutMenuSprite), not game sprites.

**Byte tables** (`*.txt`): one row of `$XX` bytes per line; `#` starts a comment (the first lines say what the table
is, each row's comment its address). The row length is only for reading: the build joins the bytes in order, so an
edit must keep the table's length (the code indexes it).

**Menus** (`menus.csv`): a menu row (`x`, `y`, `height` of its box: the count is the number of its item rows) and
an item row per line, `text` (the address of its string in MenuTexts `$70AA`) and `action` (the routine SPACE
calls, `$0000` none); `shows` is the string, for the reader (the build does not read it). The addresses are the
image's: an edit of `texts/menu.txt` that moves a string needs the item's `text` changed with it.
