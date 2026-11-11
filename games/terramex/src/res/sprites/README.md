# Sprites

24 x 24 one-bit sprites, 72 bytes each in three columns of 24 bytes (left column first, top byte first). Each PNG is
a sheet of frames with a grey line between them, white = ink; the PNG text chunk `tx-sheet` keeps the layout
(width, height, byte order, frames a row). The game draws them through the sprite space: frame F at
`$6000 + 72 x F`, `$00-$3F` the chosen explorer's set (copied to `$6000` by the selector), `$40-$7E` the creatures,
`$7F` the blank BlankSprite `$83B8` (72 zeros, kept in the code), `$80 + n` item n. RenderPass `$9B22` plots them with
a one-pixel outline (OutlineMasks `$FF00`), mirrored through BitReverse `$FE00` when flags bit 7 is set
(the stored graphics face left, so bit 7 set faces right; the right key sets it, `$A48B`).

| File | Address | Bytes | Readers | What |
| --- | --- | ---: | --- | --- |
| `creatures.png` | CreatureSprites `$7200-$83B7` | 4536 | RenderPass through the frame number | frames `$40-$7E`: the professor, the snake, the crocodile, the bird, the frog, the stone faces, the chest, the drops, the comet, the space scene's planets |
| `items.png` | ItemSprites `$8400-$8CFF` | 2304 | DrawItem `$9DF8`, DrawPortrait `$9E5D`, the bearers' items | the 32 items, frames `$80-$9F` (names below) |
| `bearers.png` | BearerFigures `$9FDE-$A0FD` | 288 | DrawBearersFigure `$9ECA` | the four invisible bearers' figures under the carried items in the panel |
| `explorer-0.png` - `explorer-4.png` | block 4 `$9CF8 + $1200 x n` (src/explorers) | 5 x 4608 | the selector's copy (CopySet48K `$C175` on a 48K; RAM 3/4 to `$6000` on a 128K), then RenderPass | the five explorers' 64 frames each: Fortisque-Smithe, Herr Krusche, Henri Beaucoup, Big John Caine, Wu Pong |

The items, in frame order (SK's names, checked against the pictures; src/res/tables/item-places.csv uses them): 0
Unicycle, 1 Flashgun, 2 Cricket Ball, 3 Spurs, 4 Beer Barrel, 5 Umbrella, 6 Bellows, 7 Party Manifesto, 8 Cannon, 9
Barrel Medium, 10 Vacuum Cleaner, 11 ACME Bridge, 12 Flute, 13 Silver Lining, 14 Spring, 15 Formula, 16 Switch, 17
Button, 18 Battery, 19 Coat Hanger, 20 Trampoline, 21 Atomic Pile, 22 Anti Rad. Pills, 23 Cup of tea, 24 Energy
Crystal, 25 Basket, 26 Balloon, 27 Barrel Big, 28 Barrel Small, 29 Silver Cross, 30 Basket 2, 31 Lift.

Frames `$7D41-$7E17` and `$82E1-$83B7` of creatures.png are drawn in no recording (c1, explorers, gameover, the 31 rzx
pieces): known only from the code that they are reachable. Twelve more sprites in this layout lie in the leftover back
buffer (leftovers/README.md).
