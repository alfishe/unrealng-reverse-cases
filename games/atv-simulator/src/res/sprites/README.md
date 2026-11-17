# sprites

| File | Address | Size | Readers |
| --- | --- | --- | --- |
| `game.png`, `game.csv` | GameGfx `$8F5C-$D6AF` | 18 260 bytes: the bank `$8F5C-$D679` and 54 leftover bytes | GameSprite `$8616` (by SpriteNum), SpriteHeader, ShiftLeftBy `$8759` / ShiftRightBy `$8777` (with RotateSpriteLeft `$871E` / RotateSpriteRight `$8742` they shift a sprite's bytes in place and keep the shift in its +3 byte) |
| `menu.png`, `menu.csv` | MenuGfx `$6338-$66FC` | 965 bytes | MenuSprite `$863D`, MenuSpriteAttrs `$773D` |

**The banks.** +0 the count (203 / 14), +1 the length word (the bank's end less its start: `$471E`, `$03C5`), +3 zero,
then a word a sprite (the game) or two a picture (the menu: the sprite's and the attributes' offsets), offsets from
the bank's start. A sprite: +0 the width in bytes, +1 the height in lines, +2 the advance (the pixels to the next
character in Print), +3 the shift its bytes are in now (0 in the image), then width x height bytes, a line at a time,
bit 7 left. A menu attribute block: +0 width, +1 height in cells, then a byte a cell.

**The files.** The PNG holds every sprite at a place of its own (index 0 paper, 1 ink, 2 no pixel); the CSV has a row
a piece in byte order: `kind` (sprite, attrs, bytes), `offset` (information: the build places the pieces one after
another), `numbers` (the sprite or picture numbers that point at it; the build makes the header's table and count
from them), `x`, `y` (its place in the PNG), `width`, `height`, `advance`, `shift`, and for attrs and bytes rows the
bytes in hex. A last `bytes` row lies after the bank's end (the length word stops before it). The codec is
`kit/sprite_bank.py` (tools/res_formats.py gives it the header fields and the table's place).

**The font.** Print (`$7608`) draws text with game sprites: `A`-`Z` are sprites `$1E-$37` (the character less `$23`),
`0`-`9` are `$99-$A2` (plus `$69`), `!` is `$56`, `"` is `$5B`, `.` is `$6F`, lower case `a`-`j` are `$8D-$96`
(the menus' key glyphs); a space moves 6 pixels, `]` moves to x `$78`, `|` ends the text.

**Leftovers.** Twelve gaps of two or four bytes between game sprites (`bytes` rows at their offsets) and the 54
bytes `$D67A-$D6AF` after the bank's end: no offset reaches them (they look like the tails of an older bank's
sprites). Known only from the code: no read of them in any recording.
