# Pictures (bank 7)

Ten whole screens packed by Ocean's LZ-and-run packer, one block after the other in RAM bank 7 from `$C000`. Each
block is unpacked straight onto the screen by UnpackPicture `$FE95` (src/bank7/unpack.asm), paged in by
DrawBank7Picture `$74AA` (bank 2). Each block is `NAME.png` (the unpacked screen, an indexed PNG whose palette index
keeps ink, paper, bright and flash: tools/res_formats.py) and `NAME.parse.txt` (the packer's own token choices, so
the block builds back byte for byte; tools/bank7pic.py has the format). Edit the PNG: when the parse no longer
unpacks to it, tools/bank7pic.py packs the new screen greedily into a valid block of the same format.

The block: +0 a size word (+2 to the end of the bit stream), +2 `$1B00`, +4 a 16-byte table of common bytes, +20 the
offset's extra bits (1), +21 the bit stream (LSB first), then two padding zeros that UnpackPicture never reads (the
only leftover bytes). After the stream UnpackPicture ORs BRIGHT (`$40`) into all attributes: the PNG shows the
screen as stored, without it.

| File | Address | Block | Tokens | What | Unpacked by |
| --- | --- | --- | --- | --- | --- |
| damage-board | `$C000` | 1811 | 1327 | the damage board with the tank drawings (the Dragonfly view's panel) | DragonflyLoop `$6C9E` |
| stores | `$C713` | 1462 | 1052 | the stores and weapons folder | bank 6 `$CAAC` |
| mission-select | `$CCC9` | 1628 | 1180 | the clipboard with the mission list | bank 6 `$C7AB` |
| grid-panel | `$D325` | 1067 | 701 | TIME, GRID Y, GRID X panel (the status view) | StatusLoop `$6BD0` |
| cockpit | `$DD75` | 1961 | 1533 | the cockpit, the 3D view's frame and dashboard | StartMission `$696D` |
| completion | `$E51E` | 1067 | 712 | the completion report, CLASSIFIED | bank 6 `$CD21`, `$CD87` |
| briefing | `$E949` | 825 | 553 | the briefing notes with the red star | bank 6 `$C9A5` |
| mission-status | `$EC82` | 2143 | 1577 | the mission status card with the commander's photo | bank 6 `$CDC2` |
| title | `$F4E1` | 1260 | 1066 | the BATTLE COMMAND lettering | bank 6 `$C431` |
| map-frame | `$F9CD` | 1218 | 885 | the map view's monitor frame | MapLoop `$6AC3` |

Bank 7 after the last block, `$D750`... is described in src/bank7/pictures.asm (Bank7Free).
