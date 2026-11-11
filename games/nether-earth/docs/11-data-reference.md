# 11. Data reference

Every data entry of the game image `$5B00`-`$FCE8`, in address order by module (`src/game/<module>.asm`):
tables, buffers, records, variables, graphics, text; an inner label (a field, a row) is a row of its own under
its entry, its size up to the next label. The name, the title and the description are the
source's (`src/game/game.ann`); the readers and writers are the routines the recordings saw touch it
(`work/game`, `work/deep`, local and not in the repository), and, marked
"(code)", the routines whose `LD` through `(nn)` reads or writes it where the recordings did not see them do so.
Written by `kit/refdocs.py`.

## viewbuffer

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$5B00` | `ViewBuffer` | 3200 | The view's back buffer: 160 lines of 20 bytes (160 x 160 pixels). The isometric view is composed here and copied to the screen at `$4021` (character columns 1-20, rows 1-20) by CopyViewToScreen, an unrolled LDI x 20 a pixel line. Line N is at `$5B00` + 20 * N, top line first. ClearViewBuffer clears it (198 x 8 PUSHes from `$6780` down, then `$5B00-$5B1F` by LDIR; SP saved in `$FD08`), FillViewCorner lays the black triangle above the map's back edge (runs of `$FF`, 10 bytes on the top 8 lines, 2 fewer each 8 lines) and DrawViewBackground the diagonal edges from ViewEdgeA / ViewEdgeB; DrawSprite blits every sprite into it (SpriteByteLoop: AND mask, OR graphic, the rows upward, 20 bytes a line). Other uses of the same bytes: ShowRobotDesign draws the robot preview of ConstructionMenu here and copies 4 bytes x 72 lines from `$6168` to the screen at `$48E0`; NuclearFlash (the nuclear blast's flash) saves the view's 20 x 20 attributes into `$5B00-$5C8F` and puts them back; the tape save / load SaveGameBlocks / LoadGameBlocks keep the 2-byte checksum of the saved block at `$5B00` (its first tape block). In the image `$5C00-$5D0D` hold 150 nonzero bytes of leftovers (probably the system variables and channel data of the load) and the rest is zero up to `$6731`; `$6732-$677F` hold 78 bytes of leftovers of the loading (ROM addresses, a BASIC stack copy), never read before the first clear. The font index (PrintChar, PrintBigChar: `$6680` + code x 8) starts inside this buffer: codes below `$20` would take their glyphs from its last 256 bytes; no text prints them. | `ClearViewBuffer`, `CopyViewToScreen`, `DrawSprite`, `ShowRobotDesign`, `LoadGameBlocks` (code) | `ClearViewBuffer`, `DrawEdgeStrips`, `DrawSprite`, `FillViewCorner`, `SaveGameBlocks` (code) |

## font

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$6780` | `Font` | 512 | Font: 64 glyphs of 8 bytes, codes `$20-$5F`. Glyph = `$6680` + code * 8, top line first, 1 = ink. Codes `$20-$5F`: space, punctuation, digits, "@" is the (c) sign, A-Z, then "[", "\", "]" and an up arrow at `$5B-$5E`, `$5F` blank. Read by PrintChar (`$D4C2`: 8 lines straight to the screen, one attribute from `$FD13` to the cell at (`$FD14`)) and PrintBigChar (`$D4F5`: each line repeated `$FD16` times; with `$FD17` >= 2 (`$D50C`) each pixel doubled to 16 pixels wide). Every text of the game goes through them (PrintInline and the number printers). Image: d1-img/6780-Font.png. | `PrintBigChar`, `PrintChar` | - |

## sprites

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$6980` | `SprTracksX` | 2 | Sprite 22 (even column; SpriteTable 44): tracks, moving along X (directions 0-1), 27 rows x 3 bytes. The sprites run from here to `$A569`, 88 blocks, each reached through SpriteTable (sprite id x 2 + the column parity). A block: the height in pixel lines, the width in bytes, then the rows from the BOTTOM line up, each row width x (mask, graphic) byte pairs: screen = (screen AND mask) OR graphic (SpriteByteLoop into ViewBuffer, DrawMaskedUp straight to the screen). The parity is bit 0 of the half-byte column DrawSprite computes (2 x X + Y - 24): the odd entry is the same picture shifted right by 4 pixels (one byte wider where it needs to), except where noted: for map objects the column parity is the row parity, and map types 12, 13, 14, 17, 18 use the two entries for two different pictures. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawSprite` | - |
| `$6982` | `SprTracksXRows` | 162 | SprTracksX: 27 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$6A24` | `SprTracksXOdd` | 2 | Sprite 22 (odd column; SpriteTable 45): tracks, moving along X (directions 0-1), 27 rows x 4 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. Also the part's icon in ConstructionMenu (`$C86D`, drawn straight to the screen by DrawMaskedUp). | `ConstructionMenu`, `DrawSprite` | - |
| `$6A26` | `SprTracksXOddRows` | 216 | SprTracksXOdd: 27 rows of 4 (mask, graphic) pairs, bottom line first | `DrawMaskedUp`, `DrawSprite` | - |
| `$6AFE` | `SprTracksY` | 2 | Sprite 23 (even column; SpriteTable 46): tracks, moving along Y (directions 2-3), 28 rows x 3 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawSprite` | - |
| `$6B00` | `SprTracksYRows` | 168 | SprTracksY: 28 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$6BA8` | `SprTracksYOdd` | 2 | Sprite 23 (odd column; SpriteTable 47): tracks, moving along Y (directions 2-3), 28 rows x 4 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawSprite` | - |
| `$6BAA` | `SprTracksYOddRows` | 224 | SprTracksYOdd: 28 rows of 4 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$6C8A` | `SprBipodX` | 2 | Sprite 24 (even column; SpriteTable 48): bipod legs, along X, 30 rows x 3 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawSprite` | - |
| `$6C8C` | `SprBipodXRows` | 180 | SprBipodX: 30 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$6D40` | `SprBipodXOdd` | 2 | Sprite 24 (odd column; SpriteTable 49): bipod legs, along X, 30 rows x 4 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. Also the part's icon in ConstructionMenu (`$C86D`, drawn straight to the screen by DrawMaskedUp). | `ConstructionMenu`, `DrawSprite` | - |
| `$6D42` | `SprBipodXOddRows` | 240 | SprBipodXOdd: 30 rows of 4 (mask, graphic) pairs, bottom line first | `DrawMaskedUp`, `DrawSprite` | - |
| `$6E32` | `SprBipodY` | 2 | Sprite 25 (even column; SpriteTable 50): bipod legs, along Y, 29 rows x 3 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawSprite` | - |
| `$6E34` | `SprBipodYRows` | 174 | SprBipodY: 29 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$6EE2` | `SprBipodYOdd` | 2 | Sprite 25 (odd column; SpriteTable 51): bipod legs, along Y, 29 rows x 4 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawSprite` | - |
| `$6EE4` | `SprBipodYOddRows` | 232 | SprBipodYOdd: 29 rows of 4 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$6FCC` | `SprAntiGrav` | 2 | Sprite 26 (even column; SpriteTable 52): anti-grav unit, every direction, 23 rows x 3 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawSprite` | - |
| `$6FCE` | `SprAntiGravRows` | 138 | SprAntiGrav: 23 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$7058` | `SprAntiGravOdd` | 2 | Sprite 26 (odd column; SpriteTable 53): anti-grav unit, every direction, 23 rows x 4 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. Also the part's icon in ConstructionMenu (`$C86D`, drawn straight to the screen by DrawMaskedUp). | `ConstructionMenu`, `DrawSprite` | - |
| `$705A` | `SprAntiGravOddRows` | 184 | SprAntiGravOdd: 23 rows of 4 (mask, graphic) pairs, bottom line first | `DrawMaskedUp`, `DrawSprite` | - |
| `$7112` | `SprCannonXp` | 2 | Sprite 27 (even column; SpriteTable 54): cannon facing X+ (direction 0), 28 rows x 3 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawSprite` | - |
| `$7114` | `SprCannonXpRows` | 168 | SprCannonXp: 28 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$71BC` | `SprCannonXpOdd` | 2 | Sprite 27 (odd column; SpriteTable 55): cannon facing X+ (direction 0), 28 rows x 4 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawSprite` | - |
| `$71BE` | `SprCannonXpOddRows` | 224 | SprCannonXpOdd: 28 rows of 4 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$729E` | `SprCannonXm` | 2 | Sprite 28 (even column; SpriteTable 56): cannon facing X- (direction 1), 30 rows x 3 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawSprite` | - |
| `$72A0` | `SprCannonXmRows` | 180 | SprCannonXm: 30 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$7354` | `SprCannonXmOdd` | 2 | Sprite 28 (odd column; SpriteTable 57): cannon facing X- (direction 1), 30 rows x 4 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. Also the part's icon in ConstructionMenu (`$C86D`, drawn straight to the screen by DrawMaskedUp). | `ConstructionMenu`, `DrawSprite` | - |
| `$7356` | `SprCannonXmOddRows` | 240 | SprCannonXmOdd: 30 rows of 4 (mask, graphic) pairs, bottom line first | `DrawMaskedUp`, `DrawSprite` | - |
| `$7446` | `SprCannonYp` | 2 | Sprite 29 (even column; SpriteTable 58): cannon facing Y+ (direction 2), 30 rows x 3 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawSprite` | - |
| `$7448` | `SprCannonYpRows` | 180 | SprCannonYp: 30 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$74FC` | `SprCannonYpOdd` | 2 | Sprite 29 (odd column; SpriteTable 59): cannon facing Y+ (direction 2), 30 rows x 4 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawSprite` | - |
| `$74FE` | `SprCannonYpOddRows` | 240 | SprCannonYpOdd: 30 rows of 4 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$75EE` | `SprCannonYm` | 2 | Sprite 30 (even column; SpriteTable 60): cannon facing Y- (direction 3), 25 rows x 3 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawSprite` | - |
| `$75F0` | `SprCannonYmRows` | 150 | SprCannonYm: 25 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$7686` | `SprCannonYmOdd` | 2 | Sprite 30 (odd column; SpriteTable 61): cannon facing Y- (direction 3), 25 rows x 4 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawSprite` | - |
| `$7688` | `SprCannonYmOddRows` | 200 | SprCannonYmOdd: 25 rows of 4 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$7750` | `SprMissilesX` | 2 | Sprite 31 (even column; SpriteTable 62): missile pod along X, 27 rows x 3 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawSprite` | - |
| `$7752` | `SprMissilesXRows` | 162 | SprMissilesX: 27 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$77F4` | `SprMissilesXOdd` | 2 | Sprite 31 (odd column; SpriteTable 63): missile pod along X, 27 rows x 4 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. Also the part's icon in ConstructionMenu (`$C86D`, drawn straight to the screen by DrawMaskedUp). | `ConstructionMenu`, `DrawSprite` | - |
| `$77F6` | `SprMissilesXOddRows` | 216 | SprMissilesXOdd: 27 rows of 4 (mask, graphic) pairs, bottom line first | `DrawMaskedUp`, `DrawSprite` | - |
| `$78CE` | `SprMissilesY` | 2 | Sprite 32 (even column; SpriteTable 64): missile pod along Y, 28 rows x 3 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawSprite` | - |
| `$78D0` | `SprMissilesYRows` | 168 | SprMissilesY: 28 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$7978` | `SprMissilesYOdd` | 2 | Sprite 32 (odd column; SpriteTable 65): missile pod along Y, 28 rows x 4 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawSprite` | - |
| `$797A` | `SprMissilesYOddRows` | 224 | SprMissilesYOdd: 28 rows of 4 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$7A5A` | `SprPhasersXp` | 2 | Sprite 33 (even column; SpriteTable 66): phasers facing X+, 28 rows x 3 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawSprite` | - |
| `$7A5C` | `SprPhasersXpRows` | 168 | SprPhasersXp: 28 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$7B04` | `SprPhasersXpOdd` | 2 | Sprite 33 (odd column; SpriteTable 67): phasers facing X+, 28 rows x 4 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawSprite` | - |
| `$7B06` | `SprPhasersXpOddRows` | 224 | SprPhasersXpOdd: 28 rows of 4 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$7BE6` | `SprPhasersXm` | 2 | Sprite 34 (even column; SpriteTable 68): phasers facing X-, 29 rows x 3 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawSprite` | - |
| `$7BE8` | `SprPhasersXmRows` | 174 | SprPhasersXm: 29 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$7C96` | `SprPhasersXmOdd` | 2 | Sprite 34 (odd column; SpriteTable 69): phasers facing X-, 29 rows x 4 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. Also the part's icon in ConstructionMenu (`$C86D`, drawn straight to the screen by DrawMaskedUp). | `ConstructionMenu` | - |
| `$7C98` | `SprPhasersXmOddRows` | 232 | SprPhasersXmOdd: 29 rows of 4 (mask, graphic) pairs, bottom line first | `DrawMaskedUp` | - |
| `$7D80` | `SprPhasersYp` | 2 | Sprite 35 (even column; SpriteTable 70): phasers facing Y+, 29 rows x 3 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawSprite` | - |
| `$7D82` | `SprPhasersYpRows` | 174 | SprPhasersYp: 29 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$7E30` | `SprPhasersYpOdd` | 2 | Sprite 35 (odd column; SpriteTable 71): phasers facing Y+, 29 rows x 4 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawSprite` | - |
| `$7E32` | `SprPhasersYpOddRows` | 232 | SprPhasersYpOdd: 29 rows of 4 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$7F1A` | `SprPhasersYm` | 2 | Sprite 36 (even column; SpriteTable 72): phasers facing Y-, 26 rows x 3 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawSprite` | - |
| `$7F1C` | `SprPhasersYmRows` | 156 | SprPhasersYm: 26 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$7FB8` | `SprPhasersYmOdd` | 2 | Sprite 36 (odd column; SpriteTable 73): phasers facing Y-, 26 rows x 4 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawSprite` | - |
| `$7FBA` | `SprPhasersYmOddRows` | 208 | SprPhasersYmOdd: 26 rows of 4 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$808A` | `SprNuclear` | 2 | Sprite 37 (even column; SpriteTable 74): nuclear bomb (the ball with the trefoil), every direction, 29 rows x 3 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. No recording drew it. | - | - |
| `$808C` | `SprNuclearRows` | 174 | SprNuclear: 29 rows of 3 (mask, graphic) pairs, bottom line first | - | - |
| `$813A` | `SprNuclearOdd` | 2 | Sprite 37 (odd column; SpriteTable 75): nuclear bomb (the ball with the trefoil), every direction, 29 rows x 4 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. Also the part's icon in ConstructionMenu (`$C86D`, drawn straight to the screen by DrawMaskedUp). | `ConstructionMenu` | - |
| `$813C` | `SprNuclearOddRows` | 232 | SprNuclearOdd: 29 rows of 4 (mask, graphic) pairs, bottom line first | `DrawMaskedUp` | - |
| `$8224` | `SprElectronicsXp` | 2 | Sprite 38 (even column; SpriteTable 76): electronics dome facing X+, 24 rows x 3 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawMaskedUp`, `DrawSprite` | - |
| `$8226` | `SprElectronicsXpRows` | 144 | SprElectronicsXp: 24 rows of 3 (mask, graphic) pairs, bottom line first | `DrawMaskedUp`, `DrawSprite` | - |
| `$82B6` | `SprElectronicsXpOdd` | 2 | Sprite 38 (odd column; SpriteTable 77): electronics dome facing X+, 24 rows x 3 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawMaskedUp`, `DrawSprite` | - |
| `$82B8` | `SprElectronicsXpOddRows` | 144 | SprElectronicsXpOdd: 24 rows of 3 (mask, graphic) pairs, bottom line first | `DrawMaskedUp`, `DrawSprite` | - |
| `$8348` | `SprElectronicsXm` | 2 | Sprite 39 (even column; SpriteTable 78): electronics dome facing X-, 24 rows x 3 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawMaskedUp`, `DrawSprite` | - |
| `$834A` | `SprElectronicsXmRows` | 144 | SprElectronicsXm: 24 rows of 3 (mask, graphic) pairs, bottom line first | `DrawMaskedUp`, `DrawSprite` | - |
| `$83DA` | `SprElectronicsXmOdd` | 2 | Sprite 39 (odd column; SpriteTable 79): electronics dome facing X-, 24 rows x 3 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. Also the part's icon in ConstructionMenu (`$C86D`, drawn straight to the screen by DrawMaskedUp). | `ConstructionMenu`, `DrawMaskedUp`, `DrawSprite` | - |
| `$83DC` | `SprElectronicsXmOddRows` | 144 | SprElectronicsXmOdd: 24 rows of 3 (mask, graphic) pairs, bottom line first | `DrawMaskedUp`, `DrawSprite` | - |
| `$846C` | `SprElectronicsYp` | 2 | Sprite 40 (even column; SpriteTable 80): electronics dome facing Y+, 24 rows x 3 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawSprite` | - |
| `$846E` | `SprElectronicsYpRows` | 144 | SprElectronicsYp: 24 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$84FE` | `SprElectronicsYpOdd` | 2 | Sprite 40 (odd column; SpriteTable 81): electronics dome facing Y+, 24 rows x 3 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawSprite` | - |
| `$8500` | `SprElectronicsYpOddRows` | 144 | SprElectronicsYpOdd: 24 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$8590` | `SprElectronicsYm` | 2 | Sprite 41 (even column; SpriteTable 82): electronics dome facing Y-, 24 rows x 3 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawSprite` | - |
| `$8592` | `SprElectronicsYmRows` | 144 | SprElectronicsYm: 24 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$8622` | `SprElectronicsYmOdd` | 2 | Sprite 41 (odd column; SpriteTable 83): electronics dome facing Y-, 24 rows x 3 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawSprite` | - |
| `$8624` | `SprElectronicsYmOddRows` | 144 | SprElectronicsYmOdd: 24 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$86B4` | `SprFlagPlayer` | 2 | Sprite 42 (even column; SpriteTable 84): the player's flag, building type 7, 11 rows x 3 bytes. Drawn by DrawCellObject on a Buildings record of this type, through the table BuildingSprites (sprite id) / BuildingSprites+9 (height). No recording drew it. | `DrawSprite` | - |
| `$86B6` | `SprFlagPlayerRows` | 66 | SprFlagPlayer: 11 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$86F8` | `SprFlagPlayerOdd` | 2 | Sprite 42 (odd column; SpriteTable 85): the player's flag, building type 7, 11 rows x 4 bytes. Drawn by DrawCellObject on a Buildings record of this type, through the table BuildingSprites (sprite id) / BuildingSprites+9 (height). | `DrawSprite` | - |
| `$86FA` | `SprFlagPlayerOddRows` | 88 | SprFlagPlayerOdd: 11 rows of 4 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$8752` | `SprFlagEnemy` | 2 | Sprite 43 (even column; SpriteTable 86): the enemy's flag, building type 8, 11 rows x 3 bytes. Drawn by DrawCellObject on a Buildings record of this type, through the table BuildingSprites (sprite id) / BuildingSprites+9 (height). No recording drew it. | `DrawSprite` | - |
| `$8754` | `SprFlagEnemyRows` | 66 | SprFlagEnemy: 11 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$8796` | `SprFlagEnemyOdd` | 2 | Sprite 43 (odd column; SpriteTable 87): the enemy's flag, building type 8, 11 rows x 4 bytes. Drawn by DrawCellObject on a Buildings record of this type, through the table BuildingSprites (sprite id) / BuildingSprites+9 (height). No recording drew it. | `DrawSprite` | - |
| `$8798` | `SprFlagEnemyOddRows` | 88 | SprFlagEnemyOdd: 11 rows of 4 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$87F0` | `SprWarbaseSign` | 2 | Sprite 44 (even column; SpriteTable 88): the warbase sign, building type 0, 17 rows x 3 bytes. Drawn by DrawCellObject on a Buildings record of this type, through the table BuildingSprites (sprite id) / BuildingSprites+9 (height). No recording drew it. | `DrawSprite` | - |
| `$87F2` | `SprWarbaseSignRows` | 102 | SprWarbaseSign: 17 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$8858` | `SprWarbaseSignOdd` | 2 | Sprite 44 (odd column; SpriteTable 89): the warbase sign, building type 0, 17 rows x 4 bytes. Drawn by DrawCellObject on a Buildings record of this type, through the table BuildingSprites (sprite id) / BuildingSprites+9 (height). | `DrawSprite` | - |
| `$885A` | `SprWarbaseSignOddRows` | 136 | SprWarbaseSignOdd: 17 rows of 4 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$88E2` | `SprShotCannonX` | 2 | Sprite 45 (even column; SpriteTable 90): cannon shell, flying along X, 16 rows x 2 bytes. Drawn by DrawMoverSprite for a Shots record: sprite id `$2B` + 2 x weapon + (direction >= 4: flying along Y). No recording drew it. | - | - |
| `$88E4` | `SprShotCannonXRows` | 64 | SprShotCannonX: 16 rows of 2 (mask, graphic) pairs, bottom line first | - | - |
| `$8924` | `SprShotCannonXOdd` | 2 | Sprite 45 (odd column; SpriteTable 91): cannon shell, flying along X, 16 rows x 2 bytes. Drawn by DrawMoverSprite for a Shots record: sprite id `$2B` + 2 x weapon + (direction >= 4: flying along Y). No recording drew it. | - | - |
| `$8926` | `SprShotCannonXOddRows` | 64 | SprShotCannonXOdd: 16 rows of 2 (mask, graphic) pairs, bottom line first | - | - |
| `$8966` | `SprShotCannonY` | 2 | Sprite 46 (even column; SpriteTable 92): cannon shell, flying along Y, 13 rows x 3 bytes. Drawn by DrawMoverSprite for a Shots record: sprite id `$2B` + 2 x weapon + (direction >= 4: flying along Y). No recording drew it. | - | - |
| `$8968` | `SprShotCannonYRows` | 78 | SprShotCannonY: 13 rows of 3 (mask, graphic) pairs, bottom line first | - | - |
| `$89B6` | `SprShotCannonYOdd` | 2 | Sprite 46 (odd column; SpriteTable 93): cannon shell, flying along Y, 13 rows x 3 bytes. Drawn by DrawMoverSprite for a Shots record: sprite id `$2B` + 2 x weapon + (direction >= 4: flying along Y). No recording drew it. | - | - |
| `$89B8` | `SprShotCannonYOddRows` | 78 | SprShotCannonYOdd: 13 rows of 3 (mask, graphic) pairs, bottom line first | - | - |
| `$8A06` | `SprShotMissileX` | 2 | Sprite 47 (even column; SpriteTable 94): missile, flying along X, 22 rows x 3 bytes. Drawn by DrawMoverSprite for a Shots record: sprite id `$2B` + 2 x weapon + (direction >= 4: flying along Y). No recording drew it. | - | - |
| `$8A08` | `SprShotMissileXRows` | 132 | SprShotMissileX: 22 rows of 3 (mask, graphic) pairs, bottom line first | - | - |
| `$8A8C` | `SprShotMissileXOdd` | 2 | Sprite 47 (odd column; SpriteTable 95): missile, flying along X, 22 rows x 4 bytes. Drawn by DrawMoverSprite for a Shots record: sprite id `$2B` + 2 x weapon + (direction >= 4: flying along Y). No recording drew it. | - | - |
| `$8A8E` | `SprShotMissileXOddRows` | 176 | SprShotMissileXOdd: 22 rows of 4 (mask, graphic) pairs, bottom line first | - | - |
| `$8B3E` | `SprShotMissileY` | 2 | Sprite 48 (even column; SpriteTable 96): missile, flying along Y, 22 rows x 3 bytes. Drawn by DrawMoverSprite for a Shots record: sprite id `$2B` + 2 x weapon + (direction >= 4: flying along Y). No recording drew it. | - | - |
| `$8B40` | `SprShotMissileYRows` | 132 | SprShotMissileY: 22 rows of 3 (mask, graphic) pairs, bottom line first | - | - |
| `$8BC4` | `SprShotMissileYOdd` | 2 | Sprite 48 (odd column; SpriteTable 97): missile, flying along Y, 22 rows x 4 bytes. Drawn by DrawMoverSprite for a Shots record: sprite id `$2B` + 2 x weapon + (direction >= 4: flying along Y). No recording drew it. | - | - |
| `$8BC6` | `SprShotMissileYOddRows` | 176 | SprShotMissileYOdd: 22 rows of 4 (mask, graphic) pairs, bottom line first | - | - |
| `$8C76` | `SprShotPhaserX` | 2 | Sprite 49 (even column; SpriteTable 98): phaser beam, along X, 17 rows x 3 bytes. Drawn by DrawMoverSprite for a Shots record: sprite id `$2B` + 2 x weapon + (direction >= 4: flying along Y). No recording drew it. | - | - |
| `$8C78` | `SprShotPhaserXRows` | 102 | SprShotPhaserX: 17 rows of 3 (mask, graphic) pairs, bottom line first | - | - |
| `$8CDE` | `SprShotPhaserXOdd` | 2 | Sprite 49 (odd column; SpriteTable 99): phaser beam, along X, 17 rows x 3 bytes. Drawn by DrawMoverSprite for a Shots record: sprite id `$2B` + 2 x weapon + (direction >= 4: flying along Y). No recording drew it. | - | - |
| `$8CE0` | `SprShotPhaserXOddRows` | 102 | SprShotPhaserXOdd: 17 rows of 3 (mask, graphic) pairs, bottom line first | - | - |
| `$8D46` | `SprShotPhaserY` | 2 | Sprite 50 (even column; SpriteTable 100): phaser beam, along Y, 20 rows x 3 bytes. Drawn by DrawMoverSprite for a Shots record: sprite id `$2B` + 2 x weapon + (direction >= 4: flying along Y). No recording drew it. | - | - |
| `$8D48` | `SprShotPhaserYRows` | 120 | SprShotPhaserY: 20 rows of 3 (mask, graphic) pairs, bottom line first | - | - |
| `$8DC0` | `SprShotPhaserYOdd` | 2 | Sprite 50 (odd column; SpriteTable 101): phaser beam, along Y, 20 rows x 3 bytes. Drawn by DrawMoverSprite for a Shots record: sprite id `$2B` + 2 x weapon + (direction >= 4: flying along Y). No recording drew it. | - | - |
| `$8DC2` | `SprShotPhaserYOddRows` | 120 | SprShotPhaserYOdd: 20 rows of 3 (mask, graphic) pairs, bottom line first | - | - |
| `$8E3A` | `SprShip` | 2 | Sprite 0 (even column; SpriteTable 0, 38, 39, 40, 41): the player's ship, 30 rows x 4 bytes. Drawn by DrawCell / ShipDraw (sprite id 0) at the height Altitude over the ship's cell. | `DrawSprite` | - |
| `$8E3C` | `SprShipRows` | 240 | SprShip: 30 rows of 4 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$8F2C` | `SprShipOdd` | 2 | Sprite 0 (odd column; SpriteTable 1): the player's ship, 30 rows x 4 bytes. Drawn by DrawCell / ShipDraw (sprite id 0) at the height Altitude over the ship's cell. | `DrawSprite` | - |
| `$8F2E` | `SprShipOddRows` | 240 | SprShipOdd: 30 rows of 4 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$901E` | `SprShadow` | 2 | Sprite 1 (even column; SpriteTable 2): the ship's shadow on the ground, 24 rows x 3 bytes. Drawn by DrawMapObjects (sprite id 1) at height 0 under the ship, before the map. | `DrawSprite` | - |
| `$9020` | `SprShadowRows` | 144 | SprShadow: 24 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$90B0` | `SprShadowOdd` | 2 | Sprite 1 (odd column; SpriteTable 3): the ship's shadow on the ground, 24 rows x 4 bytes. Drawn by DrawMapObjects (sprite id 1) at height 0 under the ship, before the map. | `DrawSprite` | - |
| `$90B2` | `SprShadowOddRows` | 192 | SprShadowOdd: 24 rows of 4 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$9172` | `SprStonesA` | 2 | Sprite 2 (both columns; SpriteTable 4, 5): stones, map type 2, 21 rows x 3 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. No recording drew it. | `DrawSprite` | - |
| `$9174` | `SprStonesARows` | 126 | SprStonesA: 21 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$91F2` | `SprStonesB` | 2 | Sprite 3 (both columns; SpriteTable 6, 7): stones, map type 3, 22 rows x 3 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. No recording drew it. | `DrawSprite` | - |
| `$91F4` | `SprStonesBRows` | 132 | SprStonesB: 22 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$9278` | `SprStonesC` | 2 | Sprite 4 (both columns; SpriteTable 8, 9): stones, map type 4, 21 rows x 3 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. No recording drew it. | `DrawSprite` | - |
| `$927A` | `SprStonesCRows` | 126 | SprStonesC: 21 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$92F8` | `SprStonesD` | 2 | Sprite 5 (both columns; SpriteTable 10, 11): stones, map type 5, 20 rows x 3 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. No recording drew it. | `DrawSprite` | - |
| `$92FA` | `SprStonesDRows` | 120 | SprStonesD: 20 rows of 3 (mask, graphic) pairs, bottom line first | - | - |
| `$9372` | `SprRocksA` | 2 | Sprite 8 (both columns; SpriteTable 16, 17): rocks, map type 8, 25 rows x 3 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. No recording drew it. | - | - |
| `$9374` | `SprRocksARows` | 150 | SprRocksA: 25 rows of 3 (mask, graphic) pairs, bottom line first | - | - |
| `$940A` | `SprRocksB` | 2 | Sprite 9 (both columns; SpriteTable 18, 19): rocks, map type 9, 26 rows x 3 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. No recording drew it. | - | - |
| `$940C` | `SprRocksBRows` | 156 | SprRocksB: 26 rows of 3 (mask, graphic) pairs, bottom line first | - | - |
| `$94A8` | `SprRocksC` | 2 | Sprite 10 (both columns; SpriteTable 20, 21): rocks, map type 10, 23 rows x 3 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. No recording drew it. | - | - |
| `$94AA` | `SprRocksCRows` | 138 | SprRocksC: 23 rows of 3 (mask, graphic) pairs, bottom line first | - | - |
| `$9534` | `SprRocksD` | 2 | Sprite 11 (both columns; SpriteTable 22, 23): rocks, map type 11, 24 rows x 3 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. No recording drew it. | - | - |
| `$9536` | `SprRocksDRows` | 144 | SprRocksD: 24 rows of 3 (mask, graphic) pairs, bottom line first | - | - |
| `$95C6` | `SprTrenchStartY` | 2 | Sprite 12 (even column; SpriteTable 24): trench start along Y (map type 12 on even rows), 20 rows x 3 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. No recording drew it. | - | - |
| `$95C8` | `SprTrenchStartYRows` | 120 | SprTrenchStartY: 20 rows of 3 (mask, graphic) pairs, bottom line first | - | - |
| `$9640` | `SprTrenchStartX` | 2 | Sprite 12 (odd column; SpriteTable 25): trench start along X (map type 12 on odd rows), 21 rows x 4 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. No recording drew it. | - | - |
| `$9642` | `SprTrenchStartXRows` | 168 | SprTrenchStartX: 21 rows of 4 (mask, graphic) pairs, bottom line first | - | - |
| `$96EA` | `SprTrenchMiddleY` | 2 | Sprite 13 (even column; SpriteTable 26): trench middle along Y (map type 13 on even rows), 23 rows x 3 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. No recording drew it. | - | - |
| `$96EC` | `SprTrenchMiddleYRows` | 138 | SprTrenchMiddleY: 23 rows of 3 (mask, graphic) pairs, bottom line first | - | - |
| `$9776` | `SprTrenchMiddleX` | 2 | Sprite 13 (odd column; SpriteTable 27): trench middle along X (map type 13 on odd rows), 21 rows x 4 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. No recording drew it. | - | - |
| `$9778` | `SprTrenchMiddleXRows` | 168 | SprTrenchMiddleX: 21 rows of 4 (mask, graphic) pairs, bottom line first | - | - |
| `$9820` | `SprTrenchEndY` | 2 | Sprite 14 (even column; SpriteTable 28): trench end along Y (map type 14 on even rows), 23 rows x 3 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. No recording drew it. | - | - |
| `$9822` | `SprTrenchEndYRows` | 138 | SprTrenchEndY: 23 rows of 3 (mask, graphic) pairs, bottom line first | - | - |
| `$98AC` | `SprTrenchEndX` | 2 | Sprite 14 (odd column; SpriteTable 29): trench end along X (map type 14 on odd rows), 17 rows x 3 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. No recording drew it. | - | - |
| `$98AE` | `SprTrenchEndXRows` | 102 | SprTrenchEndX: 17 rows of 3 (mask, graphic) pairs, bottom line first | - | - |
| `$9914` | `SprBlockLow` | 2 | Sprite 15 (even column; SpriteTable 30): low block, map type 15, 32 rows x 4 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. | `DrawSprite` | - |
| `$9916` | `SprBlockLowRows` | 256 | SprBlockLow: 32 rows of 4 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$9A16` | `SprBlockLowOdd` | 2 | Sprite 15 (odd column; SpriteTable 31): low block, map type 15, 32 rows x 4 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. | `DrawSprite` | - |
| `$9A18` | `SprBlockLowOddRows` | 256 | SprBlockLowOdd: 32 rows of 4 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$9B18` | `SprBlockTall` | 2 | Sprite 16 (even column; SpriteTable 32): tall block with an arch, map type 16, 40 rows x 4 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. | `DrawSprite` | - |
| `$9B1A` | `SprBlockTallRows` | 320 | SprBlockTall: 40 rows of 4 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$9C5A` | `SprBlockTallOdd` | 2 | Sprite 16 (odd column; SpriteTable 33): tall block with an arch, map type 16, 40 rows x 4 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. | `DrawSprite` | - |
| `$9C5C` | `SprBlockTallOddRows` | 320 | SprBlockTallOdd: 40 rows of 4 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$9D9C` | `SprBouldersA` | 2 | Sprite 6 (even column; SpriteTable 12): boulders, map type 6, 25 rows x 3 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. No recording drew it. | - | - |
| `$9D9E` | `SprBouldersARows` | 150 | SprBouldersA: 25 rows of 3 (mask, graphic) pairs, bottom line first | - | - |
| `$9E34` | `SprBouldersAOdd` | 2 | Sprite 6 (odd column; SpriteTable 13): boulders, map type 6, 24 rows x 4 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. No recording drew it. | - | - |
| `$9E36` | `SprBouldersAOddRows` | 192 | SprBouldersAOdd: 24 rows of 4 (mask, graphic) pairs, bottom line first | - | - |
| `$9EF6` | `SprBouldersB` | 2 | Sprite 7 (even column; SpriteTable 14): boulders, map type 7, 25 rows x 3 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. No recording drew it. | - | - |
| `$9EF8` | `SprBouldersBRows` | 150 | SprBouldersB: 25 rows of 3 (mask, graphic) pairs, bottom line first | - | - |
| `$9F8E` | `SprBouldersBOdd` | 2 | Sprite 7 (odd column; SpriteTable 15): boulders, map type 7, 24 rows x 4 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. No recording drew it. | - | - |
| `$9F90` | `SprBouldersBOddRows` | 192 | SprBouldersBOdd: 24 rows of 4 (mask, graphic) pairs, bottom line first | - | - |
| `$A050` | `SprPost` | 2 | Sprite 21 (both columns; SpriteTable 42, 43): border post, map type 21, 36 rows x 2 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. | `DrawSprite` | - |
| `$A052` | `SprPostRows` | 144 | SprPost: 36 rows of 2 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$A0E2` | `SprBlockDoor` | 2 | Sprite 17 (even column; SpriteTable 34): low block with a door, map type 17 on even rows, 32 rows x 4 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. | `DrawSprite` | - |
| `$A0E4` | `SprBlockDoorRows` | 256 | SprBlockDoor: 32 rows of 4 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$A1E4` | `SprBlockWindow` | 2 | Sprite 17 (odd column; SpriteTable 35): low block with a window, map type 17 on odd rows, 32 rows x 4 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. | `DrawSprite` | - |
| `$A1E6` | `SprBlockWindowRows` | 256 | SprBlockWindow: 32 rows of 4 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$A2E6` | `SprBlockGrid` | 2 | Sprite 18 (even column; SpriteTable 36): tall block with a grid face and a door, map type 18 on even rows, 40 rows x 4 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. No recording drew it. | - | - |
| `$A2E8` | `SprBlockGridRows` | 320 | SprBlockGrid: 40 rows of 4 (mask, graphic) pairs, bottom line first | - | - |
| `$A428` | `SprBlockDotted` | 2 | Sprite 18 (odd column; SpriteTable 37): tall block with a dotted face, map type 18 on odd rows, 40 rows x 4 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. No recording drew it. | - | - |
| `$A42A` | `SprBlockDottedRows` | 320 | SprBlockDotted: 40 rows of 4 (mask, graphic) pairs, bottom line first | - | - |
| `$A56A` | `SpriteSpare` | 150 | Free space after the sprites (150 zero bytes). Zero, up to Start at `$A600`; nothing in the recordings reads or writes it. | - | - |

## robotmenu

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$A738` | `RobotMenuText` | 93 | The robot menu: DIRECT CONTROL, GIVE ORDERS, COMBAT MODE, LEAVE ROBOT, -ORDERS-. A PrintInline string: (4,23) attribute `$4D`, each item two lines of 8 with an empty line between (code 3 = the next line, same column), then (17,23) attribute `$46` "-ORDERS-". | `PrintControl`, `PrintInline` | - |
| `$A7AD` | `OrderLineHead` | 5 | The order line: (18,23), attribute `$45`, then the copied name | `PrintControl`, `PrintInline` | - |
| `$A7B2` | `OrderLine` | 27 | The order's name, 27 bytes copied from OrderNames (zero in the image). Filled by ShowOrder before each print; the copied name brings its own end byte 0. | `PrintControl`, `PrintInline` | `ShowOrder` |
| `$A7D8` | `MilesPos` | 4 | (19,25), the position of the miles | `PrintControl`, `PrintInline` | - |
| `$A820` | `StrengthText` | 19 | "STRENGTH" at (22,23) attribute `$46`, then (23,25) attribute `$47` | `PrintControl`, `PrintInline` | - |
| `$A848` | `OrderNames` | 27 | The names of the orders, 27 bytes each (order 0: STOP AND DEFEND). Nine records of 27 bytes, indexed by +`$0B`: three lines of 8 joined by code 3, ended by 0. ShowOrder copies one into OrderLine. Order 0 is "  STOP  ", "  AND   ", " DEFEND ". | `PrintInline`, `ShowOrder` | - |
| `$A863` | `OrderName1` | 27 | Order 1: ADVANCE (the miles are printed into the blank middle line) | `PrintInline` | - |
| `$A87E` | `OrderName2` | 27 | Order 2: RETREAT (the miles in the middle line) | `PrintInline` | - |
| `$A899` | `OrderName3` | 27 | Order 3: DESTROY ENEMY ROBOTS | `PrintInline`, `ShowOrder` | - |
| `$A8B4` | `OrderName4` | 27 | Order 4: DESTROY ENEMY FACTORYS | `PrintInline` | - |
| `$A8CF` | `OrderName5` | 27 | Order 5: DESTROY ENEMY WARBASES | `PrintInline` | - |
| `$A8EA` | `OrderName6` | 27 | Order 6: CAPTURE NEUTRAL FACTORYS | `PrintInline`, `ShowOrder` | - |
| `$A905` | `OrderName7` | 27 | Order 7: CAPTURE ENEMY FACTORYS | `PrintInline`, `ShowOrder` | - |
| `$A920` | `OrderName8` | 27 | Order 8: CAPTURE ENEMY WARBASES | `PrintInline` | - |
| `$A977` | `OrdersMenuText` | 117 | GIVE ORDERS: SELECT ORDERS and the five items | `PrintControl`, `PrintInline` | - |
| `$AA1F` | `AdvanceTitle` | 14 | "ADVANCE " at (5,23), attribute `$4F` | `PrintInline` | - |
| `$AA32` | `RetreatTitleText` | 14 | "RETREAT " at (5,23), attribute `$4F` | `PrintInline` | - |
| `$AA43` | `DistanceText` | 43 | The distance menu: ?? MILES, SELECT DISTANCE, 0 MILES | `PrintInline` | - |
| `$AAA7` | `DistanceAtText` | 6 | PrintInline: (13,23), attribute `$46`, where the miles are printed | `PrintInline` | - |
| `$AAD8` | `DestroyMenuText` | 101 | SEARCH & DESTROY: SELECT TARGET, ENEMY ROBOTS, FACTORYS, WARBASES | `PrintControl`, `PrintInline` | - |
| `$AB54` | `CaptureMenuText` | 101 | SEARCH & CAPTURE: SELECT TARGET, NEUTRAL FACTORYS, ENEMY FACTORYS, ENEMY WARBASES | `PrintControl`, `PrintInline` | - |
| `$AC06` | `CombatMenuText` | 118 | COMBAT MODE: NUCLEAR BOMB, FIRE PHASERS, FIRE MISSILES, FIRE CANNON, MOVE ROBOT, STOP COMBAT. Printed at (4,23), attribute `$4D`, an item every 3 rows like the robot menu. | - | - |

## gameturn

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$AD88` | `ClockPos` | 8 | The clock: (0,27), setting 0, attribute `$57` | `PrintControl`, `PrintInline` | - |
| `$AE7C` | `LostText` | 51 | "YOU HAVE NO BASES LEFT", "BETTER LUCK NEXT TIME!" at (22,0), attribute `$45` | - | - |
| `$AEB7` | `WonText` | 51 | " INSIGNIANS DESTROYED ", "    YOU HAVE WON !    " at (22,0), attribute `$45` | - | - |

## ship

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$B0C1` | `BuildingTops` | 9 | The heights of the building types 0-8 for the ship and the robots. Read by ObjectTop with the type byte of the Buildings record: type 0 (the warbase pad) `$0F`, the factory types 1-6 `$16`, `$15`, `$15`, `$16`, `$16`, `$16`, types 7 and 8 `$19`. The pad's 15 is the altitude the ship sinks to on it, where ConstructionMenu opens. | `ObjectTop` | - |

## world

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$B61D` | `StepDelays` | 9 | Game turns a robot step takes: rows flat, low, high ground; columns bipod, tracks, anti-grav. 6 4 3 / 8 6 3 / 9 7 4. Read by SetStepDelay; a game turn is about 10 frames, so a bipod on flat ground steps every 60 frames. | `SetStepDelay` | - |
| `$B6B0` | `LaneSteps` | 8 | The map steps of the four directions: right +1, left -1, down +`$200`, up -`$200`. Read by ScanLane (from LD HL,`$B6AE` and two INC HL a bit of D), in the Input bit order. | `ScanLane` | - |

## level

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$BDA9` | `SceneryWest` | 208 | The scenery of columns 0-255: 69 records (tile or shape, x, y) and the 0 that ends them. Read by BuildMap through PlaceScenery with D = 0. Bit 7 clear: a 2 x 2 block of that tile; bit 7 set: shape (byte & `$7F`) of ShapeTable. Tiles used: `$02-$09` and `$0D` (low features), `$11` and `$12` (free-standing blocks, height 7 and 15: the ones a nuclear blast turns to debris). Shapes 2-10. The tile heights the ship and the robots meet are the table `$D7BC`. | `PlaceScenery` | - |
| `$BE79` | `SceneryEast` | 205 | The scenery of columns 256-511: 68 records and the 0 that ends them. Read by BuildMap through PlaceScenery with D = 1 (x + 256). The same record format as SceneryWest: bit 7 clear a 2 x 2 block of that tile (PutBlock), bit 7 set shape (byte AND `$7F`) of ShapeTable. It includes the fence posts of shape 6 at the map's right edge (503,1), (503,9). | `PlaceScenery` | - |
| `$BF46` | `BaseListWest` | 40 | The bases of columns 0-255: 13 records (type, x, y), `$FF` ends. Type 0 a warbase, 1-6 a factory making resource 1-6 (electronics, nuclear, phasers, missiles, cannon, chassis). Here: the player's warbase at (22,9) and the factories (39,6) type 4, (53,3) 6, (62,10) 1, (79,3) 5, (97,3) 3, (125,3) 2, (140,11) 6, (160,5) 1, (180,3) 3, (217,3) 4, (227,9) 5, (241,3) 6. The (x, y) is the base's door: the cell a robot stands on to capture it (the capture tick `$AD90`) and where the enemy's new robots appear (warbases). | `PlaceBases` | - |
| `$BF6E` | `BaseListEast` | 46 | The bases of columns 256-511: 15 records (type, x, y), `$FF` ends. The enemy's three warbases at (261,8), (369,8), (494,8) (given to the enemy by BuildMap) and twelve factories. With BaseListWest: 4 warbases and 24 factories, four of each type, the order of the bases table `$FD70`. | `PlaceBases` | - |
| `$BF9C` | `ShapeTable` | 22 | The shapes' addresses, index 0-10 (DrawShape). 0 the warbase, 1 the factory (both drawn by PlaceBases), 2-10 the scenery shapes (a scenery record `$82-$8A`). | `TableWord` | - |
| `$BFB2` | `ShapeWarbase` | 48 | Shape 0: the warbase, 15 blocks of tiles `$0F` (height 7) and `$10` (height 15) around the door. Steps (tile, columns, rows): a first move of (-4,-4), then blocks reaching 4 columns either side and up to 8 rows above the door. The pad, the block above the door at (x, y-4), is a tile `$10` block: altitude 15 over it is the landing height of ConstructionMenu. | `DrawShape` | - |
| `$BFE2` | `ShapeFactory` | 18 | Shape 1: the factory, tiles `$0F` at (x-2, y) and (x+2, y), `$10` on the roof row y-2 at x-2, x, x+2. The door (x, y) stays free between the two low blocks. | `DrawShape` | - |
| `$BFF4` | `ShapeLowTiles` | 36 | Shape 2: 4 x 3 blocks of tiles `$02-$05` (height 2). Steps (tile, dx, dy): 12 blocks in 3 rows of 4, each block 2 cells right of the last, a row 2 cells down (-6, 2); the tiles cycle through the four stone pictures. Drawn by DrawShape for scenery records `$82` (5 placed). Ground height 2: the ship and robots pass over it. | `DrawShape` | - |
| `$C018` | `ShapeMidTiles` | 36 | Shape 3: 4 x 3 blocks of tiles `$08-$0B` (height 6). The rock version of ShapeLowTiles: the same 3 x 4 layout with tiles `$08-$0B` (height 6). Scenery `$83`, 10 placed. | `DrawShape` | - |
| `$C03C` | `ShapeTallWallV` | 12 | Shape 4: four blocks of tile `$12` (height 15) in a column. Steps of (0, 2): a wall 2 cells thick, 8 rows long, tile `$12` (the tall block). Scenery `$84`, 3 placed. A nuclear blast can turn its blocks to debris. | `DrawShape` | - |
| `$C048` | `ShapeTallWallH` | 12 | Shape 5: four blocks of tile `$12` in a row. Steps of (2, 0): the same wall along X, 8 columns long. Scenery `$85`, 8 placed. | `DrawShape` | - |
| `$C054` | `ShapeEdgeFence` | 12 | Shape 6: four blocks of tile `$15` (height 99, impassable) in a column: the fences at both ends of the map. Placed at (12,1), (12,9), (503,1), (503,9): the row of posts at the map's left and right edges. | `DrawShape` | - |
| `$C060` | `ShapeFlatLineV` | 12 | Shape 7: tiles `$0C`, `$0D`, `$0D`, `$0E` (height 0) in a column. Steps of (0, 2): a trench along Y: start `$0C`, middle `$0D` twice, end `$0E` (height 0, drawn sunken). Scenery `$87`, 7 placed. | `DrawShape` | - |
| `$C06C` | `ShapeFlatLineH` | 12 | Shape 8: tiles `$0C`, `$0D`, `$0D`, `$0E` in a row. Steps of (2, 0): the same trench along X. Scenery `$88`, 6 placed. | `DrawShape` | - |
| `$C078` | `ShapeLowWallH` | 12 | Shape 9: four blocks of tile `$11` (height 7) in a row. Steps of (2, 0): four low blocks `$11` (height 7) in a row, a wall 8 columns long. Scenery `$89`, 10 placed. | `DrawShape` | - |
| `$C084` | `ShapeMixedWallH` | 9 | Shape 10: tiles `$11`, `$12`, `$11` in a row. Steps of (2, 0): low, tall, low (`$11`, `$12`, `$11`), 6 columns. Scenery `$8A`, 9 placed. | `DrawShape` | - |
| `$C08D` | `MapTablesSpare` | 115 | Unused: zero to `$C0FF`. 115 zero bytes between the level and the main menu (`$C100`); nothing reads or writes them. Room for a longer level description (src/res/map/level.txt may grow into it without moving the code). | - | - |

## mainmenu

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C109` | `MenuStartText` | 23 | "0..START GAME" at (11,8) in double height, yellow. PrintInline codes: attribute `$46`, setting `$21` (double height), position row 11 column 8, the text, setting `$00`. | `PrintControl`, `PrintInline` | - |
| `$C128` | `MenuKeyboardText` | 15 | Three new lines and "1..KEYBOARD" | `PrintControl`, `PrintInline` | - |
| `$C13F` | `MenuKempstonText` | 18 | Two new lines and "2..KEMPSTON J/S" | `PrintControl`, `PrintInline` | - |
| `$C159` | `MenuMoreText` | 57 | "3..INTERFACE 2", then in yellow "4..REDEFINE KEYS", "5..LOAD SAVED GAME" | `PrintControl`, `PrintInline` | - |
| `$C1E6` | `TitleText` | 22 | "NETHER" at (1,10) and "EARTH" at (5,11), attribute `$47`, setting `$32` (triple height, double width) | `PrintControl`, `PrintInline` | - |
| `$C203` | `PlayTapeText` | 27 | "PRESS PLAY ON TAPE" at (22,7), cyan, double height | - | - |
| `$C26C` | `LoadErrorText` | 22 | "LOADING ERROR!" at (22,2), white, double size | - | - |
| `$C296` | `RecordText` | 51 | "PRESS RECORD AND PLAY ", a new line, "     THEN ANY KEY     " at (22,0), cyan | - | - |
| `$C33F` | `OptionAttrPlain` | 3 | PrintInline: attribute `$46` | `PrintControl`, `PrintInline` | - |
| `$C346` | `OptionAttrChosen` | 3 | PrintInline: attribute `$45` | `PrintControl`, `PrintInline` | - |
| `$C350` | `RedefineTitleText` | 26 | "REDEFINE KEYS" at (2,9), white, double height, then position (5,3) and normal size | - | - |
| `$C382` | `KeyNameUp` | 6 | "   UP" | - | - |
| `$C391` | `KeyNameDown` | 6 | " DOWN" | - | - |
| `$C3A0` | `KeyNameLeft` | 6 | " LEFT" | - | - |
| `$C3AF` | `KeyNameRight` | 6 | "RIGHT" | - | - |
| `$C3BE` | `KeyNameFire` | 6 | " FIRE" | - | - |
| `$C3D0` | `KeyNamePause` | 6 | "PAUSE" | - | - |
| `$C3DF` | `KeyNameAbort` | 6 | "ABORT" | - | - |
| `$C3EE` | `KeyNameSave` | 6 | " SAVE" | - | - |
| `$C40F` | `PressKeyForText` | 21 | PrintInline text: new line, new line, attribute `$46`, "PRESS KEY FOR ", attribute `$45` | - | - |
| `$C42B` | `DefineKeyBlank` | 5 | PrintInline text: two spaces, attribute `$46` | - | - |
| `$C472` | `KeyNameSymShift` | 7 | PrintInline text: "SYM SH" | - | - |
| `$C481` | `KeyNameEnter` | 6 | PrintInline text: "ENTER" | - | - |
| `$C48F` | `KeyNameCapsShift` | 8 | PrintInline text: "CAPS SH" | - | - |
| `$C4A0` | `KeyNameSpace` | 6 | PrintInline text: "SPACE" | - | - |

## music

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C556` | `BassCmd1` | 3 | bass command 1: JP BassGoto (`$C5A7`), the 3-byte entry 1 | - | - |
| `$C568` | `BassCmd7` | 6 | bass commands 7 and 8: JP SetDrumTrack twice (unused, the same as command 3) | - | - |
| `$C575` | `LeadCmd1` | 3 | lead command 1: JP LeadGoto (`$C5B0`) | - | - |
| `$C57B` | `LeadCmd3` | 3 | lead command 3: JP SetDrumTrack, a bass-only handler (it reads HL', the bass track): unusable from the lead track and unused | - | - |
| `$C587` | `LeadCmd7` | 6 | lead commands 7 and 8: JP SetDrumTrack twice (unused) | - | - |
| `$C665` | `DrumTrackSteady` | 5 | drum track: a hiss every 32 frames (32 0, then 1 `$C665`). The drum tracks: records of (frames, kind[, p]) and gotos 1 aa; DrumStep. This one plays at the start and at the end of each pass of the tune; docs r4.md. | `DrumStep` | - |
| `$C66A` | `DrumTrackUnused` | 2 | a hiss record (32 0) that no goto reaches | - | - |
| `$C66C` | `DrumTrackBeat` | 12 | drum track: rasp 16, hiss 8, hiss 8, sweep `$30` for 32 frames (64 frames), loops. Started by the bass track's command 3 `$C66C` after the four intro riffs. | - | - |
| `$C678` | `BassTrack` | 69 | the bass track: commands of 3 bytes (drums, pattern calls, the goto back). 3 `$C665`, 4 x 2 `$C6BD` (the riff), 3 `$C66C`, 2 x 2 `$C6CC`, 8 x 2 `$C6DD`, 5 x 2 `$C6CC`, 3 `$C665`, 1 `$C678`: 5120 frames. | `BassCall`, `BassNextEvent`, `SetDrumTrack` | - |
| `$C6BD` | `BassRiff` | 15 | bass pattern: the 128-frame intro riff on `$7C` with rests, then `$52`. Notes are (period, frames), commands 4 / 5 one byte: `$7C` 16, off, `$7C` 8, on, `$7C` 16, off, `$7C` 64, `$52` 24, on, return. | `BassNextEvent` | - |
| `$C6CC` | `BassWalk` | 17 | bass pattern: `$7C` `$6E` `$68` `$5D` twice, 64 frames each (512 frames) | - | - |
| `$C6DD` | `BassRun` | 37 | bass pattern: `$7C` in eighths with rests, then the run `$8B` `$93` `$A5` `$BA` `$A5` `$93` `$8B` `$7C` `$8B` `$93` `$A5` (128 frames) | - | - |
| `$C702` | `LeadTrack` | 135 | the lead track: pattern calls, two long notes, the goto back. 4 x riff `$C789`, 4 x phrase `$C7AA`, off, `$C7AA`, on, 5 x `$C7C5`, then `$C7D2` / `$C7C5` three times in turns, `$3E` 32, `$37` 32, 2 x `$C7AA`, 4 x the scale `$C7DF`, 4 x `$C789`, 8 x `$C7C5`, 4 x `$C789`, 1 `$C702`: 5120 frames. | `LeadCall`, `LeadNextEvent` | - |
| `$C789` | `LeadRiff` | 33 | lead pattern: `$37` with rests, then trills `$29` / `$2E`, `$37`, `$3E` (128 frames) | `LeadNextEvent` | - |
| `$C7AA` | `LeadPhrase` | 27 | lead pattern: the tune's phrase `$29` `$2E` `$31` `$37` `$3E` `$49` `$3E` `$45` `$2E` `$29` `$2E` `$34` `$2E` (256 frames) | - | - |
| `$C7C5` | `LeadArpeggioA` | 13 | lead pattern: `$3E` `$52` `$7C` twice (64 frames) | - | - |
| `$C7D2` | `LeadArpeggioB` | 13 | lead pattern: `$45` `$5D` `$8B` twice (64 frames) | - | - |
| `$C7DF` | `LeadScale` | 65 | lead pattern: the 16-note scale `$29` up to `$BA` (high to low) twice, 4 frames a note (128 frames) | - | - |

## construction

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C8BE` | `ConstructionTitleText` | 31 | PrintInline text: "ROBOT" (double size) at row 0, "CONSTRUCTION" (double height) at row 2. Setting `$22` = double height, double width; `$21` = double height; `$00` = normal (PrintInline code 4: high nibble the height, low nibble the width). | `PrintControl`, `PrintInline` | - |
| `$C8DD` | `PartNamesText` | 85 | PrintInline text: the part names at column 21, ELECTRONICS row 1 down to BIPOD row 22, every 3 rows | `PrintControl`, `PrintInline` | - |
| `$C932` | `ExitStartText` | 24 | PrintInline text: "EXIT START" / "MENU ROBOT" at rows 21-22, columns 5 and 10 | `PrintControl`, `PrintInline` | - |
| `$C94A` | `PartCostsText` | 36 | PrintInline text: the costs under the names at column 22: 3 20 4 4 2 10 5 3 (the same numbers as PartCosts) | `PrintControl`, `PrintInline` | - |
| `$C96E` | `ResourceNamesText` | 121 | PrintInline text: "-- RESOURCES --" / "-- AVAILABLE --", GENERAL row 9, ELECTRONICS-CHASSIS rows 11-16, TOTAL row 18 | `PrintControl`, `PrintInline` | - |
| `$CAF0` | `PartCosts` | 16 | the parts' cost (bipod, tracks, anti-grav, cannon, missiles, phasers, nuclear, electronics), then the resource each takes first (an index into Resources). The second row is the resource index (6 chassis x3, 5 cannon, 4 missiles, 3 phasers, 2 nuclear, 1 electronics); what the own resource lacks comes from general (index 0). | `ConstructionMenuLoop`, `EnemyCommander` | - |
| `$CBFF` | `TotalPosition` | 4 | PrintInline text: AT 18,12 | `PrintControl`, `PrintInline` | - |
| `$CC10` | `MenuResourcePos` | 4 | Inline string: position (row patched, column 13). PrintInline bytes: 1 Y X with Y written by `$CC0A`, then 0 (end). | `PrintControl`, `PrintInline` | `PrintMenuResource` |

## view

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$CE56` | `BuildingSprites` | 9 | The sprite of each building type. Index = the Buildings type: 0 the player's warbase pad `$2C` (a crate), factories 1 electronics `$28`, 2 nuclear `$25`, 3 phasers `$23`, 4 missiles `$20`, 5 cannon `$1D`, 6 chassis `$17` (each the robot part of its product, facing down: `$16` + the parts table `$D6C8`), 7 and 8 the flags `$2A` and `$2B`. In the deep recording at frame 20000 the type 7 / 8 records stand two columns left of a factory (four of the player's warbase pad): a factory's owner flag; 7 the player's, 8 the enemy's. The bytes: `$2C`, `$28`, `$25`, `$23`, `$20`, `$1D`, `$17`, `$2A`, `$2B`. Read by DrawBuilding. | `DrawCellObject` | - |
| `$CE5F` | `BuildingHeights` | 9 | The height each building sprite is drawn at. Type 0 at `$13`, the six factory signs at `$0F` (on the factory's roof blocks), the flags at `$1A`: the bytes `$13`, `$0F` x 6, `$1A`, `$1A`. Read by DrawBuilding into DrawSprite's height operand. Not the heights the ship lands on: those are BuildingTops (the world module). | `DrawCellObject` | - |

## screen

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$D1C5` | `PlayScreenText` | 32 | Inline string: " DAY:" and "TIME:" at (0,22), the tall "RADAR:" at (22,0). PrintInline bytes: attribute `$57`, position (0,22), size 0, " DAY:", newline, "TIME:", position (22,0), size `$21` (2 rows high, 1 byte wide), attribute `$45`, "RADAR:", 0. Bright white on red for the clock labels, bright cyan on black for RADAR:. PrintInline returns past the 0 into ShowStatusPanel: DrawPlayScreen has no RET of its own. | `PrintControl`, `PrintInline` | - |
| `$D1EB` | `StatusPanelText` | 168 | Inline string: the STATUS and RESOURCES labels of the right panel. "  STATUS" at (3,22) attribute `$46`, "INSG  HUMN" (Insignians, the enemy; Humans, the player), then from (6,23) attribute `$45` the rows WARBASES, ELECTR'S, NUCLEAR, PHASERS, MISSILES, CANNON, CHASSIS, ROBOTS; "RESOURCES" at (15,23) attribute `$46` and from row 17 attribute `$44` GENERAL, ELECTR', NUCLEAR, PHASERS, MISSILE, CANNON, CHASSIS: the order of Resources. | `PrintControl`, `PrintInline` | - |
| `$D29B` | `ResourceValuesPos` | 8 | Inline string: position (16,30), attribute `$4E`, size 0. The bytes 1 `$10` `$1E` (position (16,30)), 2 `$4E` (attribute bright yellow on blue), 4 0 (normal size), 0. Row 16: PrintResourceValues starts with a newline. | `PrintControl`, `PrintInline` | - |
| `$D2BB` | `InsgCountsPos` | 6 | Inline string: position (6,22), attribute `$47`. The bytes 1 6 `$16` (position (6,22)), 2 `$47` (bright white on black), 0. | `PrintControl`, `PrintInline` | - |
| `$D2CE` | `HumnCountsPos` | 4 | Inline string: position (6,31). The bytes 1 6 `$1F` (position (6,31)), 0; the attribute stays `$47`. | `PrintControl`, `PrintInline` | - |
| `$D2DB` | `HumnRobotsPos` | 4 | Inline string: position (13,30). The bytes 1 `$0D` `$1E` (position (13,30)), 0. | `PrintControl`, `PrintInline` | - |
| `$D2F9` | `ClearPanelPos` | 8 | Inline string: position (2,22), size 0, attribute 0. The bytes 1 2 `$16` (position (2,22)), 4 0 (normal size), 2 0 (attribute 0), 0. | `PrintControl`, `PrintInline` | - |
| `$D306` | `PanelBlankLine` | 12 | Inline string: 10 spaces, newline. 10 spaces (columns 22-31), 3 (the next row, the same column), 0. | `PrintInline` | - |

## controls

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$D3CC` | `KeyTable` | 24 | the keys, eight of 3 bytes: the port high byte, the bit mask, the key code (shown by the redefine menu). The bytes as built: F7 01 31 (key 1, Input bit 7, pause), DF 04 49 (I, bit 6, abort), F7 10 35 (5, bit 5, save), 7F 02 82 (SYMBOL SHIFT, bit 4, fire), FB 01 51 (Q, bit 3, up), FD 01 41 (A, bit 2, down), DF 02 4F (O, bit 1, left), DF 01 50 (P, bit 0, right). A key is LD A,(port byte) / IN A,(`$FE`) / AND mask: Z when pressed. The code byte only serves the redefine screen (it prints the key and refuses one already taken). The ninth byte, `$D3E4`, is Controls: 1 in the image (the keyboard only); MainMenu sets 1-3 by the keys 1, 2, 3. | `ReadControls` | - |
| `$D3E4` | `Controls` | 1 | the menu's choice: 1 keyboard, 2 Kempston, 3 Interface 2 | `ControlsOptionAttr`, `ReadControls` | `MainMenuKeys` |

## tables

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$D6A8` | `ViewEdgeA` | 16 | View edge, black on the left: 8 lines of 2 bytes. `$FFFF`, `$FFFC`, `$FFF0` ... `$C000`: a staircase 2 pixels a line. DrawViewBackground copies it with DrawEdgeStrips (2 bytes a line, 8 lines, then 2 bytes left) 6 times from `$5B0A`, the lower edge of the black triangle above the map, and 3 times from `$5FB2`. Image: d1-img/D6A8-ViewEdges.png. | `DrawEdgeStrips` | - |
| `$D6B8` | `ViewEdgeB` | 16 | View edge, black on the right: 8 lines of 2 bytes. `$0003`, `$000F` ... `$FFFF`; DrawViewBackground copies it 4 times from `$6512`: with the 3 copies of ViewEdgeA at `$5FB2` it makes the black band along the map's front edge, bottom right of the view. | `DrawEdgeStrips` | - |
| `$D6C8` | `PartSpriteTable` | 32 | Robot part sprites: 8 parts x 4 directions, sprite id - `$16`. Row = part (bipod, tracks, anti-grav, cannon, missiles, phasers, nuclear, electronics), column = direction (the number of the lowest set bit of robot +`$08`: 0 X+, 1 X-, 2 Y+, 3 Y-). Read by DirectionLoop (`$CF16`; sprite id = byte + `$16`, then DrawSprite) for robots in the view and by ConstructionMenu (`$C87B`; column 1, the odd-column sprite via SpriteTable+`$58`) for the part icons. Bipod, tracks and missiles have one picture per axis, anti-grav and nuclear one for all four. The rows, as sprite ids: bipod `$18`, `$18`, `$19`, `$19`; tracks `$16`, `$16`, `$17`, `$17`; anti-grav `$1A` x 4; cannon `$1B-$1E`; missiles `$1F`, `$1F`, `$20`, `$20`; phasers `$21-$24`; nuclear `$25` x 4; electronics `$26-$29`. Note the part order of the rows (bipod first) against the sprite order (tracks first). | `ConstructionMenu`, `DrawRobotPart` | - |
| `$D6E8` | `SpriteTable` | 204 | Sprite pointers: 51 sprite ids x (even column, odd column). Word = the sprite block for index id x 2 + parity (DrawSprite: AND `$3F`, SRA L / ADC A,A, then TableWord). Ids 0 ship, 1 shadow, 2-18 and 21 map types (2-5 stones, 6-7 boulders, 8-11 rocks, 12-14 trench, 15-18 blocks, 21 post), 19-20 unused (they point at the ship), 22-41 robot parts (PartSpriteTable), 42 the player's flag, 43 the enemy's flag, 44 the warbase sign, 45-50 shots (cannon, missile, phaser; X then Y). ConstructionMenu reads from SpriteTable+`$58` (id 22 on). Read by TableWord (`$D34C`/`$D34E`). | `TableWord` | - |
| `$D7B4` | `PartHeights` | 8 | Height of each robot part in units (bipod `$0B`, tracks 7, anti-grav 8, cannon 6, missiles 6, phasers 7, nuclear 7, electronics 7). Indexed by the part number. DirectionLoop (`$CF28`) adds it to the draw height after each part, so the parts stack; SpawnHeightLoop (`$B911`) sums it over robot +`$07` into +`$09`, the robot's height, when a robot is made. | `DrawRobotPart`, `EnemyCommander` | - |
| `$D7BC` | `TerrainHeights` | 23 | Height of each map cell type (0-22). Indexed by cell AND `$1F`: 0-1 0, stones 2-5 2, boulders 6-7 3, rocks 8-11 6, trench 12-14 0, blocks 15 7, 16 15, 17 7, 18 15, 19-20 0, the post 21 99 (no flight over it), 22 0. Read only by TerrainTop (`$B093`), the height under a cell for CheckShipMove (CellTop) and for shots and robots (GroundUnderFootprint). | `TerrainTop` | - |

## worldstate

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$D7D3` | `Shots` | 45 | Shots in flight: 5 records of 9 bytes. +0/+1 the map cell (+1 = 0: free), +2/+3 X, +4 Y, +5 the direction (bit 0 X+2, 1 X-2, 2 Y+2, 3 Y-2), +6 steps left (5, 7 for missiles, 1 more with electronics), +7 the weapon (1 cannon, 2 missiles, 3 phasers: a random one of the robot's weapon bits 3-5), +8 the flight height (`$0A`: a cell at least that high stops it). FindFreeShot gives a robot a free slot of two: the player's at `$D7DC` / `$D7E5`, the enemy's at `$D7EE` / `$D7F7`; the first record `$D7D3` is the player's COMBAT MODE shot, fired by CombatFireShot when it is free (FindFreeShot never hands it out). FireShot fires, UpdateShot (from WorldTurn, every turn) moves and hits, DrawCellObject / DrawMoverSprite draw. Cleared by the start-up (`$A661`), saved and loaded through SaveShots. | `FindFreeShot`, `FireShot`, `MoveShot`, `NewGameSetup`, `UpdateShot` +1 | `FireShot`, `MoveShot`, `NewGameSetup`, `ShotGone`, `UpdateShot` |
| `$D800` | `RadarOwn` | 256 | Radar bitmap with the player's robots: 16 lines of 16 bytes. One pixel line per map row, one bit per map column, 128 columns from the radar's left edge (`$FD1C`, moved by 64 columns at a time). BuildRadar builds it (a bit is set where cell AND `$1F` >= `$0F`: blocks and posts), copies it to RadarEnemy, then ToggleRadarDot XORs a 2-line marker for every robot into the player's or the enemy's copy by the side bit of +`$0A` (also when a robot moves, PlaceRobot / RobotStep). PlayInterrupt shows the two copies on alternate frames (`$FD1A`) with ShowRadar at `$50C6` (16 lines, 16 bytes) and attributes `$4D` / `$4E` in rows 22-23, so each side's robots blink in their own colour. Cleared with the map by BuildMap (`$BC87`). | `BuildMap`, `BuildRadar`, `ShowRadar`, `ToggleRadarDot` | `BuildMap`, `BuildRadar`, `ToggleRadarDot` |
| `$D900` | `RadarEnemy` | 43 | Radar bitmap with the enemy's robots: 16 lines of 16 bytes. The copy of RadarOwn the enemy's markers are XORed into; shown with attribute `$4E`. The save stages its last 213 bytes (`$D92B-$D9FF`) as SaveShots and SaveBuildings: the radar is rebuilt afterwards. | `ShowRadar` | `BuildRadar` |
| `$D92B` | `SaveShots` | 45 | Save / load staging: the 5 Shots records. SaveGameBlocks (save) copies Shots here and Buildings after it, then writes two headerless tape blocks with the ROM's SA-BYTES: the 2-byte sum of the second (at ViewBuffer) and `$24D1` bytes from here to `$FDFB` (staging, robots, map, the variables `$FD00-$FDFB`). LoadGameBlocks loads both, checks the sum (SaveChecksum) and copies the records back, else LOADING ERROR. Shares the bytes of RadarEnemy. | `ShowRadar` | `BuildRadar` |
| `$D958` | `SaveBuildings` | 168 | Save / load staging: the 56 Buildings records. 168 bytes, copied from and back to Buildings (`$FF01`) by SaveGameBlocks / LoadGameBlocks. | `ShowRadar`, `ToggleRadarDot` | `BuildRadar`, `ToggleRadarDot` |
| `$DA00` | `Robots` | 384 | The player's robots: slots 0-23, 16 bytes a record. +0/+1 the map cell (+1 = 0: a free slot), +2/+3 X, +4 Y, +5 the last move's direction (likely), +6 a counter (unverified), +7 parts (bit 0 bipod ... 7 electronics), +8 direction (bit 0 X+, 1 X-, 2 Y+, 3 Y-), +9 height (the sum of PartHeights), +`$0A` side / menu flags (1 the ship sits on it, 2 direct control, bit 7 enemy), +`$0B` order, +`$0C` strength (`$64` at birth), +`$0D` the height its parts are drawn from (0, 2, 6 seen), +`$0E` target slot / distance, +`$0F` the move timer (RobotStep DEC, acts at 0). Walked by WorldTurn (every turn: UpdateRobot), FindRobot, BuildRadar, ConstructionMenu (a free slot of 0-23), the AI (ConsiderBuilding, TargetRobotRecord, FindNearestOpponent: the other side's array). Cleared by the start-up (`$A63A`, 768 bytes with EnemyRobots). | `BuildRadar`, `ConsiderBuilding`, `ConstructionMenu`, `CountLiveRobots`, `DrawCellObject` +26 | `ConstructionMenuSetup`, `DrawCellObject`, `MoveShot`, `NewGameSetup`, `PlaceRobot` +9 |
| `$DB80` | `EnemyRobots` | 384 | The enemy's robots: slots 24-47, the same records. +`$0A` has bit 7 set. EnemyCommander makes one (slot = an index x 16 from here); ConsiderBuilding, TargetRobotRecord and FindNearestOpponent search this array or Robots by the side in `$FD51`. | `BuildRadar`, `ConsiderBuilding`, `CountLiveRobots`, `EnemyCommander`, `FindFreeShot` +18 | `EnemyCommander`, `MoveShot`, `NewGameSetup`, `PlaceRobot`, `RobotStep` +4 |

## map

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$DD00` | `Map` | 8154 | The map: 16 rows of 512 cells, cell = `$DD00` + `$200` x Y + X. A cell: bits 0-4 the type (0 empty; 2-18 and 21 terrain and blocks, drawn through SpriteTable; TerrainHeights), bit 5 a covered cell of a 2 x 2 object (PutBlock writes the type at the anchor and type + `$20` at the other 3: DrawCell draws only the anchor), bit 6 a robot, a building or a shot stands here (FindRobot / FindBuilding look it up), bit 7 the ship is over this cell (set where the ship moves, ShipCell; DrawCell draws the ship in the depth order of this cell, `$FD11`). Zero in the image: BuildMap clears it (`$BC7A`) and builds it from the level description at SceneryWest (objects of 2 x 2 tiles through the shape table at SceneryWest+`$1F3`). The view reads 16 rows x 32 columns from MapView (DrawMapObjects; one map row is 16 lines of 32 here); BuildRadar reads 128 columns for the radar. The last row ends at `$FCFF`, 23 bytes past the image. | `AddBuilding`, `BuildMap`, `BuildRadar`, `CanMoveDown`, `CanMoveLeft` +22 | `AddBuilding`, `BuildMap`, `DrawCell`, `DrawCellObject`, `LiftShipFromMap` +7 |
| `$FCDA` | `MapTail` | 15 | The map's last 15 image bytes: they load over the loader N1. Row 15, columns 474-488. The game block ends here, laid over the first 15 bytes of N1 (`$FCDA-$FD8D`, the relocated LD-BYTES that is loading it), code that has already run. Zero, part of the map. Columns 489-511 (`$FCE9-$FCFF`) lie past the image, over the rest of N1. | `BuildMap`, `CanMoveDown`, `CanMoveLeft`, `CanMoveRight`, `PlaceRobot` +4 | `BuildMap`, `PlaceRobot`, `PutBlock`, `UpdateRobot` |
