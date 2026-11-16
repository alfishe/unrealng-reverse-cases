# tables

| File | Address | Size | Format | Readers |
| --- | --- | --- | --- | --- |
| `panels.csv` | PanelP1Sprites `$6C9E-$6D50` | 179 | the sprite lists PanelP1Sprites, PanelP2Sprites, HudSprites, LoadIntroSprites and the box lists LoadIntroBoxes, PanelP2Boxes, PanelP1Boxes, HudBoxes | SpriteList (`$6C17`), AttrBoxes (from PanelP1, PanelP2, ShowHud, LoadIntro) |
| `credits.csv` | TrailIntroBoxes `$6ED7-$6F0D` | 55 | the box lists TrailIntroBoxes, CreditBoxes, the sprite lists CreditSprites1, CreditSprites2, then HiScorePage `$6F0D` (one byte) | TrailIntro, Credits, HiScoreScreen |
| `menus.csv` | MenuDefs `$702A-$70A9` | 128 | the eight menus | MenuBox, MenuDraw, MenuDispatch |

**Lists** (`panels.csv`, `credits.csv`): a row an item, `list,x,y,x2,y2,sprite,attr,bytes`. A sprite item has x, y
and the game sprite (3 bytes); a box item has x1, y1, x2, y2 and the attribute (5 bytes); each list ends with `$FF`,
written by the build where the next list's name starts. A `bytes` row holds bytes as they are (HiScorePage).

**Menus** (`menus.csv`): a menu row (`x`, `y`, `height` of its box: the count is the number of its item rows) and
an item row per line, `text` (the address of its string in MenuTexts `$70AA`) and `action` (the routine SPACE
calls, `$0000` none); `shows` is the string, for the reader (the build does not read it). The addresses are the
image's: an edit of `texts/menu.txt` that moves a string needs the item's `text` changed with it.
