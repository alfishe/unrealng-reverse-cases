# 11. Data reference

Every data entry of every annotated part of both releases, part by part, in address order by module: tables,
buffers, records, graphics, text. The name, the title and the description are the source's (the part's `.ann`); the
readers and writers are the routines the part's recordings saw touch it (local, not in the repository). The
records of the work space past the images (robots `$DA00`, shots `$D7D3`, the map `$DD00`, buildings `$FF01`,
capture points `$FD70`) are laid out in [7. Objects](07-objects.md); the texts are in [8](08-hud-and-text.md) and
[texts/](texts/README.md); the tunes in [9](09-sound.md).

Written by `python3 tools/zsB_refdocs.py` (through `kit/refdocs.py`).

The parts:

- The '99 game (`src/game99`)
- The '98 game (`src/game98`)
- The '98 intro (`src/intro98`)
- The '99 stage 2: the intro (`src/stage2`)
- The '99 pictures block (`src/pictures99`)
- The '99 music block (`src/music99`)
- The '99 stage 3: System checking (`src/stage3`)
- The '99 start-up menu (`src/menu99`)
- The '99 patches block: `diskread` (`src/patches99`)
- The '99 patches block: `diskmap` (`src/patches99`)
- The '99 patches block: `paging128` (`src/patches99`)
- The '99 patches block: `menu128` (`src/patches99`)
- The '99 patches block: `taperead` (`src/patches99`)
- The '99 patches block: `tapemap` (`src/patches99`)
- The '99 patches block: `textload48` (`src/patches99`)
- The '99 patches block: `menu48` (`src/patches99`)

## The '99 game (`src/game99`)

Recordings: `work/zsB/deep` (the bot's game on HARD, built-in level, 30602 frames from START (doc 10)), `work/zsB/deep-map0` (the bot's game on HARD with NELEV_00 (LOAD MAP), 24416 frames: fights (doc 10)), `work/stage2/game99/r99-play` (the start-up menu, LOAD MAP, HARD + PHASERS, play), `work/stage2/game99/crit-play` (CRITICAL with every upgrade, several game days), `work/stage2/game99/loadmap-menu` (LOAD MAP: the catalogue and a map loaded).

### font

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$6780` | `Font` | 512 | Font: 64 glyphs of 8 bytes, codes `$20-$5F`. Glyph = `$6680` + code * 8, top line first, 1 = ink. Codes `$20-$5F`: space, punctuation, digits, "@" (an at sign), A-Z, then "[", "\", "]" and an up arrow at `$5B-$5E`, `$5F` an underline. Not Nether Earth's font: the letters and digits are 6 pixels wide on 6 lines, their left stroke doubled in the lower half; ten glyphs are Nether Earth's (space, #, *, +, -, ., =, ], the arrow, the underline). Read by PrintChar (`$D4C2`: 8 lines straight to the screen, one attribute from `$FD13` to the cell at (`$FD14`)) and PrintBigChar (`$D4F5`: each line repeated `$FD16` times; with `$FD17` >= 2 (`$D50C`) each pixel doubled to 16 pixels wide). Every text of the game goes through them (PrintInline and the number printers). Image: d1-img/6780-Font.png. | `PrintBigChar`, `PrintChar`, `PrintControl` | - |

### sprites

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
| `$75F0` | `SprCannonYmRows` | 150 | SprCannonYm: 25 rows of 3 (mask, graphic) pairs, bottom line first. Differs from Nether Earth's block in `$767F` (`$04`, NE `$E0`): graphic bytes (the second of a (mask, graphic) pair), a few pixels of the picture changed. | `DrawSprite` | - |
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
| `$7C96` | `SprPhasersXmOdd` | 2 | Sprite 34 (odd column; SpriteTable 69): phasers facing X-, 29 rows x 4 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. Also the part's icon in ConstructionMenu (`$C86D`, drawn straight to the screen by DrawMaskedUp). | `ConstructionMenu`, `DrawSprite` | - |
| `$7C98` | `SprPhasersXmOddRows` | 232 | SprPhasersXmOdd: 29 rows of 4 (mask, graphic) pairs, bottom line first | `DrawMaskedUp`, `DrawSprite` | - |
| `$7D80` | `SprPhasersYp` | 2 | Sprite 35 (even column; SpriteTable 70): phasers facing Y+, 29 rows x 3 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawSprite` | - |
| `$7D82` | `SprPhasersYpRows` | 174 | SprPhasersYp: 29 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$7E30` | `SprPhasersYpOdd` | 2 | Sprite 35 (odd column; SpriteTable 71): phasers facing Y+, 29 rows x 4 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawSprite` | - |
| `$7E32` | `SprPhasersYpOddRows` | 232 | SprPhasersYpOdd: 29 rows of 4 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$7F1A` | `SprPhasersYm` | 2 | Sprite 36 (even column; SpriteTable 72): phasers facing Y-, 26 rows x 3 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawSprite` | - |
| `$7F1C` | `SprPhasersYmRows` | 156 | SprPhasersYm: 26 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$7FB8` | `SprPhasersYmOdd` | 2 | Sprite 36 (odd column; SpriteTable 73): phasers facing Y-, 26 rows x 4 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawSprite` | - |
| `$7FBA` | `SprPhasersYmOddRows` | 208 | SprPhasersYmOdd: 26 rows of 4 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$808A` | `SprNuclear` | 2 | Sprite 37 (even column; SpriteTable 74): nuclear bomb (the ball with the trefoil), every direction, 29 rows x 3 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawSprite` | - |
| `$808C` | `SprNuclearRows` | 174 | SprNuclear: 29 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$813A` | `SprNuclearOdd` | 2 | Sprite 37 (odd column; SpriteTable 75): nuclear bomb (the ball with the trefoil), every direction, 29 rows x 4 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. Also the part's icon in ConstructionMenu (`$C86D`, drawn straight to the screen by DrawMaskedUp). | `ConstructionMenu`, `DrawSprite` | - |
| `$813C` | `SprNuclearOddRows` | 232 | SprNuclearOdd: 29 rows of 4 (mask, graphic) pairs, bottom line first | `DrawMaskedUp`, `DrawSprite` | - |
| `$8224` | `SprElectronicsXp` | 2 | Sprite 38 (even column; SpriteTable 76): electronics dome facing X+, 24 rows x 3 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawMaskedUp`, `DrawSprite` | - |
| `$8226` | `SprElectronicsXpRows` | 144 | SprElectronicsXp: 24 rows of 3 (mask, graphic) pairs, bottom line first | `DrawMaskedUp`, `DrawSprite` | - |
| `$82B6` | `SprElectronicsXpOdd` | 2 | Sprite 38 (odd column; SpriteTable 77): electronics dome facing X+, 24 rows x 3 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawMaskedUp`, `DrawSprite` | - |
| `$82B8` | `SprElectronicsXpOddRows` | 144 | SprElectronicsXpOdd: 24 rows of 3 (mask, graphic) pairs, bottom line first | `DrawMaskedUp`, `DrawSprite` | - |
| `$8348` | `SprElectronicsXm` | 2 | Sprite 39 (even column; SpriteTable 78): electronics dome facing X-, 24 rows x 3 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawMaskedUp`, `DrawSprite` | - |
| `$834A` | `SprElectronicsXmRows` | 144 | SprElectronicsXm: 24 rows of 3 (mask, graphic) pairs, bottom line first. Differs from Nether Earth's block in `$837F` (`$1F`, NE `$80`), `$8383` (`$1C`, NE `$5E`): graphic bytes (the second of a (mask, graphic) pair), a few pixels of the picture changed. | `DrawMaskedUp`, `DrawSprite` | - |
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
| `$86B4` | `SprFlagPlayer` | 2 | Sprite 42 (even column; SpriteTable 84): the player's flag, building type 7, 11 rows x 3 bytes. Drawn by DrawCellObject on a Buildings record of this type, through the table BuildingSprites (sprite id) / BuildingSprites+9 (height). | `DrawSprite` | - |
| `$86B6` | `SprFlagPlayerRows` | 66 | SprFlagPlayer: 11 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$86F8` | `SprFlagPlayerOdd` | 2 | Sprite 42 (odd column; SpriteTable 85): the player's flag, building type 7, 11 rows x 4 bytes. Drawn by DrawCellObject on a Buildings record of this type, through the table BuildingSprites (sprite id) / BuildingSprites+9 (height). | `DrawSprite` | - |
| `$86FA` | `SprFlagPlayerOddRows` | 88 | SprFlagPlayerOdd: 11 rows of 4 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$8752` | `SprFlagEnemy` | 2 | Sprite 43 (even column; SpriteTable 86): the enemy's flag, building type 8, 11 rows x 3 bytes. Drawn by DrawCellObject on a Buildings record of this type, through the table BuildingSprites (sprite id) / BuildingSprites+9 (height). | `DrawSprite` | - |
| `$8754` | `SprFlagEnemyRows` | 66 | SprFlagEnemy: 11 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$8796` | `SprFlagEnemyOdd` | 2 | Sprite 43 (odd column; SpriteTable 87): the enemy's flag, building type 8, 11 rows x 4 bytes. Drawn by DrawCellObject on a Buildings record of this type, through the table BuildingSprites (sprite id) / BuildingSprites+9 (height). | `DrawSprite` | - |
| `$8798` | `SprFlagEnemyOddRows` | 88 | SprFlagEnemyOdd: 11 rows of 4 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$87F0` | `SprWarbaseSign` | 2 | Sprite 44 (even column; SpriteTable 88): the warbase sign, building type 0, 17 rows x 3 bytes. Drawn by DrawCellObject on a Buildings record of this type, through the table BuildingSprites (sprite id) / BuildingSprites+9 (height). | `DrawSprite` | - |
| `$87F2` | `SprWarbaseSignRows` | 102 | SprWarbaseSign: 17 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$8858` | `SprWarbaseSignOdd` | 2 | Sprite 44 (odd column; SpriteTable 89): the warbase sign, building type 0, 17 rows x 4 bytes. Drawn by DrawCellObject on a Buildings record of this type, through the table BuildingSprites (sprite id) / BuildingSprites+9 (height). | `DrawSprite` | - |
| `$885A` | `SprWarbaseSignOddRows` | 136 | SprWarbaseSignOdd: 17 rows of 4 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$88E2` | `SprShotCannonX` | 2 | Sprite 45 (even column; SpriteTable 90): cannon shell, flying along X, 16 rows x 2 bytes. Drawn by DrawMoverSprite for a Shots record: sprite id `$2B` + 2 x weapon + (direction >= 4: flying along Y). | `DrawSprite` | - |
| `$88E4` | `SprShotCannonXRows` | 64 | SprShotCannonX: 16 rows of 2 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$8924` | `SprShotCannonXOdd` | 2 | Sprite 45 (odd column; SpriteTable 91): cannon shell, flying along X, 16 rows x 2 bytes. Drawn by DrawMoverSprite for a Shots record: sprite id `$2B` + 2 x weapon + (direction >= 4: flying along Y). | `DrawSprite` | - |
| `$8926` | `SprShotCannonXOddRows` | 64 | SprShotCannonXOdd: 16 rows of 2 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$8966` | `SprShotCannonY` | 2 | Sprite 46 (even column; SpriteTable 92): cannon shell, flying along Y, 13 rows x 3 bytes. Drawn by DrawMoverSprite for a Shots record: sprite id `$2B` + 2 x weapon + (direction >= 4: flying along Y). | - | - |
| `$8968` | `SprShotCannonYRows` | 78 | SprShotCannonY: 13 rows of 3 (mask, graphic) pairs, bottom line first | - | - |
| `$89B6` | `SprShotCannonYOdd` | 2 | Sprite 46 (odd column; SpriteTable 93): cannon shell, flying along Y, 13 rows x 3 bytes. Drawn by DrawMoverSprite for a Shots record: sprite id `$2B` + 2 x weapon + (direction >= 4: flying along Y). | - | - |
| `$89B8` | `SprShotCannonYOddRows` | 78 | SprShotCannonYOdd: 13 rows of 3 (mask, graphic) pairs, bottom line first | - | - |
| `$8A06` | `SprShotMissileX` | 2 | Sprite 47 (even column; SpriteTable 94): missile, flying along X, 22 rows x 3 bytes. Drawn by DrawMoverSprite for a Shots record: sprite id `$2B` + 2 x weapon + (direction >= 4: flying along Y). | - | - |
| `$8A08` | `SprShotMissileXRows` | 132 | SprShotMissileX: 22 rows of 3 (mask, graphic) pairs, bottom line first | - | - |
| `$8A8C` | `SprShotMissileXOdd` | 2 | Sprite 47 (odd column; SpriteTable 95): missile, flying along X, 22 rows x 4 bytes. Drawn by DrawMoverSprite for a Shots record: sprite id `$2B` + 2 x weapon + (direction >= 4: flying along Y). | - | - |
| `$8A8E` | `SprShotMissileXOddRows` | 176 | SprShotMissileXOdd: 22 rows of 4 (mask, graphic) pairs, bottom line first | - | - |
| `$8B3E` | `SprShotMissileY` | 2 | Sprite 48 (even column; SpriteTable 96): missile, flying along Y, 22 rows x 3 bytes. Drawn by DrawMoverSprite for a Shots record: sprite id `$2B` + 2 x weapon + (direction >= 4: flying along Y). | - | - |
| `$8B40` | `SprShotMissileYRows` | 132 | SprShotMissileY: 22 rows of 3 (mask, graphic) pairs, bottom line first | - | - |
| `$8BC4` | `SprShotMissileYOdd` | 2 | Sprite 48 (odd column; SpriteTable 97): missile, flying along Y, 22 rows x 4 bytes. Drawn by DrawMoverSprite for a Shots record: sprite id `$2B` + 2 x weapon + (direction >= 4: flying along Y). | - | - |
| `$8BC6` | `SprShotMissileYOddRows` | 176 | SprShotMissileYOdd: 22 rows of 4 (mask, graphic) pairs, bottom line first | - | - |
| `$8C76` | `SprShotPhaserX` | 2 | Sprite 49 (even column; SpriteTable 98): phaser beam, along X, 17 rows x 3 bytes. Drawn by DrawMoverSprite for a Shots record: sprite id `$2B` + 2 x weapon + (direction >= 4: flying along Y). | - | - |
| `$8C78` | `SprShotPhaserXRows` | 102 | SprShotPhaserX: 17 rows of 3 (mask, graphic) pairs, bottom line first | - | - |
| `$8CDE` | `SprShotPhaserXOdd` | 2 | Sprite 49 (odd column; SpriteTable 99): phaser beam, along X, 17 rows x 3 bytes. Drawn by DrawMoverSprite for a Shots record: sprite id `$2B` + 2 x weapon + (direction >= 4: flying along Y). | `DrawSprite` | - |
| `$8CE0` | `SprShotPhaserXOddRows` | 102 | SprShotPhaserXOdd: 17 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$8D46` | `SprShotPhaserY` | 2 | Sprite 50 (even column; SpriteTable 100): phaser beam, along Y, 20 rows x 3 bytes. Drawn by DrawMoverSprite for a Shots record: sprite id `$2B` + 2 x weapon + (direction >= 4: flying along Y). | - | - |
| `$8D48` | `SprShotPhaserYRows` | 120 | SprShotPhaserY: 20 rows of 3 (mask, graphic) pairs, bottom line first | - | - |
| `$8DC0` | `SprShotPhaserYOdd` | 2 | Sprite 50 (odd column; SpriteTable 101): phaser beam, along Y, 20 rows x 3 bytes. Drawn by DrawMoverSprite for a Shots record: sprite id `$2B` + 2 x weapon + (direction >= 4: flying along Y). | - | - |
| `$8DC2` | `SprShotPhaserYOddRows` | 120 | SprShotPhaserYOdd: 20 rows of 3 (mask, graphic) pairs, bottom line first | - | - |
| `$8E3A` | `SprShip` | 2 | Sprite 0 (even column; SpriteTable 0, 38, 39, 40, 41): the player's ship, 30 rows x 4 bytes. Drawn by DrawCell / ShipDraw (sprite id 0) at the height Altitude over the ship's cell. | `DrawSprite` | - |
| `$8E3C` | `SprShipRows` | 240 | SprShip: 30 rows of 4 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$8F2C` | `SprShipOdd` | 2 | Sprite 0 (odd column; SpriteTable 1): the player's ship, 30 rows x 4 bytes. Drawn by DrawCell / ShipDraw (sprite id 0) at the height Altitude over the ship's cell. | `DrawSprite` | - |
| `$8F2E` | `SprShipOddRows` | 240 | SprShipOdd: 30 rows of 4 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$901E` | `SprShadow` | 2 | Sprite 1 (even column; SpriteTable 2): the ship's shadow on the ground, 24 rows x 3 bytes. Drawn by DrawMapObjects (sprite id 1) at height 0 under the ship, before the map. | `DrawSprite` | - |
| `$9020` | `SprShadowRows` | 144 | SprShadow: 24 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$90B0` | `SprShadowOdd` | 2 | Sprite 1 (odd column; SpriteTable 3): the ship's shadow on the ground, 24 rows x 4 bytes. Drawn by DrawMapObjects (sprite id 1) at height 0 under the ship, before the map. | `DrawSprite` | - |
| `$90B2` | `SprShadowOddRows` | 192 | SprShadowOdd: 24 rows of 4 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$9172` | `SprStonesA` | 2 | Sprite 2 (both columns; SpriteTable 4, 5): stones, map type 2, 21 rows x 3 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. | `DrawSprite` | - |
| `$9174` | `SprStonesARows` | 126 | SprStonesA: 21 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$91F2` | `SprStonesB` | 2 | Sprite 3 (both columns; SpriteTable 6, 7): stones, map type 3, 22 rows x 3 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. | `DrawSprite` | - |
| `$91F4` | `SprStonesBRows` | 132 | SprStonesB: 22 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$9278` | `SprStonesC` | 2 | Sprite 4 (both columns; SpriteTable 8, 9): stones, map type 4, 21 rows x 3 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. | `DrawSprite` | - |
| `$927A` | `SprStonesCRows` | 126 | SprStonesC: 21 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$92F8` | `SprStonesD` | 2 | Sprite 5 (both columns; SpriteTable 10, 11): stones, map type 5, 20 rows x 3 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. | `DrawSprite` | - |
| `$92FA` | `SprStonesDRows` | 120 | SprStonesD: 20 rows of 3 (mask, graphic) pairs, bottom line first | - | - |
| `$9372` | `SprRocksA` | 2 | Sprite 8 (both columns; SpriteTable 16, 17): rocks, map type 8, 25 rows x 3 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. | - | - |
| `$9374` | `SprRocksARows` | 150 | SprRocksA: 25 rows of 3 (mask, graphic) pairs, bottom line first | - | - |
| `$940A` | `SprRocksB` | 2 | Sprite 9 (both columns; SpriteTable 18, 19): rocks, map type 9, 26 rows x 3 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. | - | - |
| `$940C` | `SprRocksBRows` | 156 | SprRocksB: 26 rows of 3 (mask, graphic) pairs, bottom line first | - | - |
| `$94A8` | `SprRocksC` | 2 | Sprite 10 (both columns; SpriteTable 20, 21): rocks, map type 10, 23 rows x 3 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. | - | - |
| `$94AA` | `SprRocksCRows` | 138 | SprRocksC: 23 rows of 3 (mask, graphic) pairs, bottom line first | - | - |
| `$9534` | `SprRocksD` | 2 | Sprite 11 (both columns; SpriteTable 22, 23): rocks, map type 11, 24 rows x 3 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. | - | - |
| `$9536` | `SprRocksDRows` | 144 | SprRocksD: 24 rows of 3 (mask, graphic) pairs, bottom line first | - | - |
| `$95C6` | `SprTrenchStartY` | 2 | Sprite 12 (even column; SpriteTable 24): trench start along Y (map type 12 on even rows), 20 rows x 3 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. | - | - |
| `$95C8` | `SprTrenchStartYRows` | 120 | SprTrenchStartY: 20 rows of 3 (mask, graphic) pairs, bottom line first | - | - |
| `$9640` | `SprTrenchStartX` | 2 | Sprite 12 (odd column; SpriteTable 25): trench start along X (map type 12 on odd rows), 21 rows x 4 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. | - | - |
| `$9642` | `SprTrenchStartXRows` | 168 | SprTrenchStartX: 21 rows of 4 (mask, graphic) pairs, bottom line first | - | - |
| `$96EA` | `SprTrenchMiddleY` | 2 | Sprite 13 (even column; SpriteTable 26): trench middle along Y (map type 13 on even rows), 23 rows x 3 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. | - | - |
| `$96EC` | `SprTrenchMiddleYRows` | 138 | SprTrenchMiddleY: 23 rows of 3 (mask, graphic) pairs, bottom line first | - | - |
| `$9776` | `SprTrenchMiddleX` | 2 | Sprite 13 (odd column; SpriteTable 27): trench middle along X (map type 13 on odd rows), 21 rows x 4 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. | - | - |
| `$9778` | `SprTrenchMiddleXRows` | 168 | SprTrenchMiddleX: 21 rows of 4 (mask, graphic) pairs, bottom line first | - | - |
| `$9820` | `SprTrenchEndY` | 2 | Sprite 14 (even column; SpriteTable 28): trench end along Y (map type 14 on even rows), 23 rows x 3 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. | - | - |
| `$9822` | `SprTrenchEndYRows` | 138 | SprTrenchEndY: 23 rows of 3 (mask, graphic) pairs, bottom line first. Differs from Nether Earth's block in `$985D` (`$56`, NE `$50`): graphic bytes (the second of a (mask, graphic) pair), a few pixels of the picture changed. | - | - |
| `$98AC` | `SprTrenchEndX` | 2 | Sprite 14 (odd column; SpriteTable 29): trench end along X (map type 14 on odd rows), 17 rows x 3 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. | - | - |
| `$98AE` | `SprTrenchEndXRows` | 102 | SprTrenchEndX: 17 rows of 3 (mask, graphic) pairs, bottom line first | - | - |
| `$9914` | `SprBlockLow` | 2 | Sprite 15 (even column; SpriteTable 30): low block, map type 15, 32 rows x 4 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. | `DrawSprite` | - |
| `$9916` | `SprBlockLowRows` | 256 | SprBlockLow: 32 rows of 4 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$9A16` | `SprBlockLowOdd` | 2 | Sprite 15 (odd column; SpriteTable 31): low block, map type 15, 32 rows x 4 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. | `DrawSprite` | - |
| `$9A18` | `SprBlockLowOddRows` | 256 | SprBlockLowOdd: 32 rows of 4 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$9B18` | `SprBlockTall` | 2 | Sprite 16 (even column; SpriteTable 32): tall block with an arch, map type 16, 40 rows x 4 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. | `DrawSprite` | - |
| `$9B1A` | `SprBlockTallRows` | 320 | SprBlockTall: 40 rows of 4 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$9C5A` | `SprBlockTallOdd` | 2 | Sprite 16 (odd column; SpriteTable 33): tall block with an arch, map type 16, 40 rows x 4 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. | `DrawSprite` | - |
| `$9C5C` | `SprBlockTallOddRows` | 320 | SprBlockTallOdd: 40 rows of 4 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$9D9C` | `SprBouldersA` | 2 | Sprite 6 (even column; SpriteTable 12): boulders, map type 6, 25 rows x 3 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. | - | - |
| `$9D9E` | `SprBouldersARows` | 150 | SprBouldersA: 25 rows of 3 (mask, graphic) pairs, bottom line first | - | - |
| `$9E34` | `SprBouldersAOdd` | 2 | Sprite 6 (odd column; SpriteTable 13): boulders, map type 6, 24 rows x 4 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. | - | - |
| `$9E36` | `SprBouldersAOddRows` | 192 | SprBouldersAOdd: 24 rows of 4 (mask, graphic) pairs, bottom line first | - | - |
| `$9EF6` | `SprBouldersB` | 2 | Sprite 7 (even column; SpriteTable 14): boulders, map type 7, 25 rows x 3 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. | `DrawSprite` | - |
| `$9EF8` | `SprBouldersBRows` | 150 | SprBouldersB: 25 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$9F8E` | `SprBouldersBOdd` | 2 | Sprite 7 (odd column; SpriteTable 15): boulders, map type 7, 24 rows x 4 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. | - | - |
| `$9F90` | `SprBouldersBOddRows` | 192 | SprBouldersBOdd: 24 rows of 4 (mask, graphic) pairs, bottom line first | - | - |
| `$A050` | `SprPost` | 2 | Sprite 21 (both columns; SpriteTable 42, 43): border post, map type 21, 36 rows x 2 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. | `DrawSprite` | - |
| `$A052` | `SprPostRows` | 144 | SprPost: 36 rows of 2 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$A0E2` | `SprBlockDoor` | 2 | Sprite 17 (even column; SpriteTable 34): low block with a door, map type 17 on even rows, 32 rows x 4 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. | `DrawSprite` | - |
| `$A0E4` | `SprBlockDoorRows` | 256 | SprBlockDoor: 32 rows of 4 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$A1E4` | `SprBlockWindow` | 2 | Sprite 17 (odd column; SpriteTable 35): low block with a window, map type 17 on odd rows, 32 rows x 4 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. | `DrawSprite` | - |
| `$A1E6` | `SprBlockWindowRows` | 256 | SprBlockWindow: 32 rows of 4 (mask, graphic) pairs, bottom line first | `DrawSprite` | - |
| `$A2E6` | `SprBlockGrid` | 2 | Sprite 18 (even column; SpriteTable 36): tall block with a grid face and a door, map type 18 on even rows, 40 rows x 4 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. | - | - |
| `$A2E8` | `SprBlockGridRows` | 320 | SprBlockGrid: 40 rows of 4 (mask, graphic) pairs, bottom line first | - | - |
| `$A428` | `SprBlockDotted` | 2 | Sprite 18 (odd column; SpriteTable 37): tall block with a dotted face, map type 18 on odd rows, 40 rows x 4 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. | - | - |
| `$A42A` | `SprBlockDottedRows` | 320 | SprBlockDotted: 40 rows of 4 (mask, graphic) pairs, bottom line first | - | - |

### difficulty

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$A56A` | `PieceRoomA56A` | 46 | Zero: stage 3 copies paging128 or textload48 here (`$A56A-$A597`). On 128 K the patches block's paging128 (41 bytes, `$DA3F`), on one page or tape textload48 (46 bytes, `$DAE7`). The block's 46 zero bytes never run. | - | - |
| `$A598` | `DiskReadLeftover` | 4 | The first 4 bytes of diskread: LD IX,`$2F65` (DD 21 65 2F). Stage 3 copies diskread (or taperead) over `$A598-$A5D5`, so these bytes are always replaced. They equal the first instruction of diskread, which reads a sector through the TR-DOS ROM routine `$2F65`: a leftover of the author's own image, where the reader had been placed. | - | - |
| `$A59C` | `PieceRoomA59C` | 58 | Zero: the rest of the reader's room, up to `$A5D5`. 58 zero bytes, replaced by diskread's (or taperead's) next bytes. | - | - |

### start

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$A718` | `SaveCallRemoved` | 8 | SaveCallRemoved | - | - |

### robotmenu

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$A738` | `RobotMenuText` | 93 | The robot menu: DIRECT CONTROL, GIVE ORDERS, COMBAT MODE, LEAVE ROBOT, -ORDERS-. A PrintInline string: (4,23) attribute `$4D`, each item two lines of 8 with an empty line between (code 3 = the next line, same column), then (17,23) attribute `$46` "-ORDERS-". | `PrintControl`, `PrintInline` | - |
| `$A7AD` | `OrderLineHead` | 5 | The order line: (18,23), attribute `$45`, then the copied name | `PrintControl`, `PrintInline` | - |
| `$A7B2` | `OrderLine` | 27 | The order's name, 27 bytes copied from OrderNames: the image holds STOP AND DEFEND. Filled by ShowOrder before each print; the copied name brings its own end byte 0. The block was saved from a running game, so the buffer holds the last name copied into it, order 0's "  STOP  ", "  AND   ", " DEFEND " (code 3 between the lines), the same bytes as the first name of OrderNames. | `PrintControl`, `PrintInline` | `ShowOrder` |
| `$A7D8` | `MilesPos` | 4 | (19,25), the position of the miles | `PrintControl`, `PrintInline` | - |
| `$A820` | `StrengthText` | 19 | "STRENGTH" at (22,23) attribute `$46`, then (23,25) attribute `$47` | `PrintControl`, `PrintInline` | - |
| `$A848` | `OrderNames` | 27 | The names of the orders, 27 bytes each (order 0: STOP AND DEFEND). Nine records of 27 bytes, indexed by +`$0B`: three lines of 8 joined by code 3, ended by 0. ShowOrder copies one into OrderLine. Order 0 is " STOP ", " AND ", " DEFEND ". | `ShowOrder` | - |
| `$A863` | `OrderName1` | 27 | Order 1: ADVANCE (the miles are printed into the blank middle line) | - | - |
| `$A87E` | `OrderName2` | 27 | Order 2: RETREAT (the miles in the middle line) | - | - |
| `$A899` | `OrderName3` | 27 | Order 3: DESTROY ENEMY ROBOTS | `ShowOrder` | - |
| `$A8B4` | `OrderName4` | 27 | Order 4: DESTROY ENEMY FACTORYS | - | - |
| `$A8CF` | `OrderName5` | 27 | Order 5: DESTROY ENEMY WARBASES | - | - |
| `$A8EA` | `OrderName6` | 27 | Order 6: CAPTURE NEUTRAL FACTORYS | `ShowOrder` | - |
| `$A905` | `OrderName7` | 27 | Order 7: CAPTURE ENEMY FACTORYS | `ShowOrder` | - |
| `$A920` | `OrderName8` | 27 | Order 8: CAPTURE ENEMY WARBASES | `ShowOrder` | - |
| `$A977` | `OrdersMenuText` | 117 | GIVE ORDERS: SELECT ORDERS and the five items | `PrintControl`, `PrintInline` | - |
| `$AA1F` | `AdvanceTitle` | 14 | "ADVANCE " at (5,23), attribute `$4F` | - | - |
| `$AA32` | `RetreatTitleText` | 14 | "RETREAT " at (5,23), attribute `$4F` | - | - |
| `$AA43` | `DistanceText` | 43 | The distance menu: ?? MILES, SELECT DISTANCE, 0 MILES | - | - |
| `$AAA7` | `DistanceAtText` | 6 | PrintInline: (13,23), attribute `$46`, where the miles are printed | - | - |
| `$AAD8` | `DestroyMenuText` | 101 | SEARCH & DESTROY: SELECT TARGET, ENEMY ROBOTS, FACTORYS, WARBASES | `PrintControl`, `PrintInline` | - |
| `$AB54` | `CaptureMenuText` | 101 | SEARCH & CAPTURE: SELECT TARGET, NEUTRAL FACTORYS, ENEMY FACTORYS, ENEMY WARBASES | `PrintControl`, `PrintInline` | - |
| `$AC06` | `CombatMenuText` | 118 | COMBAT MODE: NUCLEAR BOMB, FIRE PHASERS, FIRE MISSILES, FIRE CANNON, MOVE ROBOT, STOP COMBAT. Printed at (4,23), attribute `$4D`, an item every 3 rows like the robot menu. | - | - |

### gameturn

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$AD88` | `ClockPos` | 8 | The clock: (0,27), setting 0, attribute `$57` | `PrintControl`, `PrintInline` | - |
| `$AE7C` | `LostText` | 51 | "YOU HAVE NO BASES LEFT", "BETTER LUCK NEXT TIME!" at (22,0), attribute `$45` | - | - |
| `$AEB7` | `WonText` | 51 | " INSIGNIANS DESTROYED ", "   CONGRATULATIONS!   " at (22,0), attribute `$45`. The PrintInline string of a won game, over the radar rows. The second line reads CONGRATULATIONS! (NE: YOU HAVE WON !), centred in the same 22 characters. | - | - |

### ship

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$B0C1` | `BuildingTops` | 9 | The heights of the building types 0-8 for the ship and the robots. Read by ObjectTop with the type byte of the Buildings record: type 0 (the warbase pad) `$0F`, the factory types 1-6 `$16`, `$15`, `$15`, `$16`, `$16`, `$16`, types 7 and 8 `$19`. The pad's 15 is the altitude the ship sinks to on it, where ConstructionMenu opens. | `ObjectTop` | - |

### world

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$B61D` | `StepDelays` | 9 | Game turns a robot step takes: rows flat, low, high ground; columns bipod, tracks, anti-grav. 6 4 3 / 8 6 3 / 9 7 4. Read by SetStepDelay; a game turn is about 10 frames, so a bipod on flat ground steps every 60 frames. | `SetStepDelay` | - |
| `$B6B0` | `LaneSteps` | 8 | The map steps of the four directions: right +1, left -1, down +`$200`, up -`$200`. Read by ScanLane (from LD HL,`$B6AE` and two INC HL a bit of D), in the Input bit order. | `ScanLane` | - |

### level

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$BDA9` | `SceneryWest` | 166 | The scenery of columns 0-255: 55 records (tile or shape, x, y) and the 0 that ends them. Read by BuildMap through PlaceScenery with D = 0. Bit 7 clear: a 2 x 2 block of that tile; bit 7 set: shape (byte & `$7F`) of ShapeTable. Here: four edge fences (shape 6) at columns 12 and 24, around the player's warbase, and the letters of ЗАГРУЗИСЬ at columns 30-101, rows 3-12: tile `$11` (low block) for the З, tile `$12` (tall block) and tall walls (shape 4) for the rest. | `PlaceScenery` | - |
| `$BE4F` | `SceneryEast` | 13 | The scenery of columns 256-511: 4 records and the 0 that ends them. Read by BuildMap through PlaceScenery with D = 1 (x + 256): four edge fences (shape 6) at columns 491 and 503, rows 1 and 9, around the enemy's warbase. | `PlaceScenery` | - |
| `$BE5C` | `BaseListWest` | 4 | The bases of columns 0-255: the player's warbase at (18,8), `$FF` ends. Type 0 a warbase, 1-6 a factory making resource 1-6 (electronics, nuclear, phasers, missiles, cannon, chassis). The (x, y) is the base's door. The first warbase placed is record 0, the player's. | `PlaceBases`, `PlaceScenery` | - |
| `$BE60` | `BaseListEast` | 4 | The bases of columns 256-511: the enemy's warbase at (497,8), `$FF` ends. Record 1, given to the enemy by BuildMap's loop. | `PlaceBases`, `PlaceScenery` | - |
| `$BE64` | `LevelSpare` | 312 | The rest of the lists' room: zero up to `$BF9B`. 312 zero bytes. A NELEV file's lists may fill the room up to `$BF9B`: LOAD MAP copies `$1F3` bytes from `$BDA9` whatever the lists use. | `PlaceBases`, `PlaceScenery` | - |
| `$BF9C` | `ShapeTable` | 22 | The shapes' addresses, index 0-10 (DrawShape). 0 the warbase, 1 the factory (both drawn by PlaceBases), 2-10 the scenery shapes (a scenery record `$82-$8A`). | `TableWord` | - |
| `$BFB2` | `ShapeWarbase` | 48 | Shape 0: the warbase, 15 blocks of tiles `$0F` (height 7) and `$10` (height 15) around the door. Steps (tile, columns, rows): a first move of (-4,-4), then blocks reaching 4 columns either side and up to 8 rows above the door. The pad, the block above the door at (x, y-4), is a tile `$10` block: altitude 15 over it is the landing height of ConstructionMenu. | `DrawShape` | - |
| `$BFE2` | `ShapeFactory` | 18 | Shape 1: the factory, tiles `$0F` at (x-2, y) and (x+2, y), `$10` on the roof row y-2 at x-2, x, x+2. The door (x, y) stays free between the two low blocks. | `DrawShape` | - |
| `$BFF4` | `ShapeLowTiles` | 36 | Shape 2: 4 x 3 blocks of tiles `$02-$05` (height 2). Steps (tile, dx, dy): 12 blocks in 3 rows of 4, each block 2 cells right of the last, a row 2 cells down (-6, 2; the tiles cycle through the four stone pictures. Drawn by DrawShape for scenery records `$82` (5 placed). Ground height 2: the ship and robots pass over it. | `DrawShape` | - |
| `$C018` | `ShapeMidTiles` | 36 | Shape 3: 4 x 3 blocks of tiles `$08-$0B` (height 6). The rock version of ShapeLowTiles: the same 3 x 4 layout with tiles `$08-$0B` (height 6). Scenery `$83`, 10 placed. | `DrawShape` | - |
| `$C03C` | `ShapeTallWallV` | 12 | Shape 4: four blocks of tile `$12` (height 15) in a column. Steps of (0, 2): a wall 2 cells thick, 8 rows long, tile `$12` (the tall block). Scenery `$84`, 3 placed. A nuclear blast can turn its blocks to debris. | `DrawShape` | - |
| `$C048` | `ShapeTallWallH` | 12 | Shape 5: four blocks of tile `$12` in a row. Steps of (2, 0): the same wall along X, 8 columns long. Scenery `$85`, 8 placed. | `DrawShape` | - |
| `$C054` | `ShapeEdgeFence` | 12 | Shape 6: four blocks of tile `$15` (height 99, impassable) in a column: the fences at both ends of the map. Placed at (12,1), (12,9), (503,1), (503,9): the row of posts at the map's left and right edges. | `DrawShape` | - |
| `$C060` | `ShapeFlatLineV` | 12 | Shape 7: tiles `$0C`, `$0D`, `$0D`, `$0E` (height 0) in a column. Steps of (0, 2): a trench along Y: start `$0C`, middle `$0D` twice, end `$0E` (height 0, drawn sunken). Scenery `$87`, 7 placed. | `DrawShape` | - |
| `$C06C` | `ShapeFlatLineH` | 12 | Shape 8: tiles `$0C`, `$0D`, `$0D`, `$0E` in a row. Steps of (2, 0): the same trench along X. Scenery `$88`, 6 placed. | `DrawShape` | - |
| `$C078` | `ShapeLowWallH` | 12 | Shape 9: four blocks of tile `$11` (height 7) in a row. Steps of (2, 0): four low blocks `$11` (height 7) in a row, a wall 8 columns long. Scenery `$89`, 10 placed. | `DrawShape` | - |
| `$C084` | `ShapeMixedWallH` | 9 | Shape 10: tiles `$11`, `$12`, `$11` in a row. Steps of (2, 0): low, tall, low (`$11`, `$12`, `$11`), 6 columns. Scenery `$8A`, 9 placed. | `DrawShape` | - |
| `$C08D` | `MapTablesSpare` | 115 | Unused: zero to `$C0FF`. 115 zero bytes between the level and the main menu (`$C100`; nothing reads or writes them. The lists' room before them ends at `$BF9B`; these bytes follow the shapes. | - | - |

### mainmenu

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C100` | `MenuPieceRoom` | 127 | Zero: stage 3 copies the start-up menu's piece here (menu128 or menu48). The 127 bytes `$C100-$C17E`. On 128 K stage 3 copies the patches block's menu128 piece here (`$6340`), on one page or the tape path menu48 (`$6329`): a table of jumps whose first, `JP $C112` / the 48 K one, is the start-up menu Start calls. The block's zeros never run. | - | - |
| `$C17F` | `MainMenuSpare` | 126 | Zero, never written: NE's main menu keys, title and load code were here. `$C17F-$C1FC`: nothing writes or reads these bytes in the '99 program. | - | - |
| `$C1FD` | `LoadMapRoom` | 310 | Zero: stage 3 copies LOAD MAP here (diskmap from disk, tapemap on the tape path). The 310 bytes `$C1FD-$C332`, the size of the disk piece; the tape piece takes 147. The start-up menu's LOAD MAP item jumps to `$C1FD`; the piece reads a NELEV file, copies its lists over `$BDA9-$BF9B` and its tail into the game's operands (src/res/maps/README.md), then jumps to Start. | `PrintControl`, `PrintInline` | - |
| `$C333` | `WaitAnyKeyEnd` | 3 | Two zeros and `$C9`, the RET that ended NE's WaitAnyKey. Never run: nothing calls `$C325` any more. | - | - |
| `$C33F` | `OptionAttrPlain` | 3 | PrintInline: attribute `$46` | - | - |
| `$C346` | `OptionAttrChosen` | 3 | PrintInline: attribute `$45` | - | - |
| `$C350` | `RedefineTitleText` | 26 | "REDEFINE KEYS" at (2,9), white, double height, then position (5,3) and normal size | - | - |
| `$C382` | `KeyNameUp` | 6 | "   UP" | - | - |
| `$C391` | `KeyNameDown` | 6 | " DOWN" | - | - |
| `$C3A0` | `KeyNameLeft` | 6 | " LEFT" | - | - |
| `$C3AF` | `KeyNameRight` | 6 | "RIGHT" | - | - |
| `$C3BE` | `KeyNameFire` | 6 | " FIRE" | - | - |
| `$C3D0` | `KeyNamePause` | 6 | "PAUSE" | - | - |
| `$C3DF` | `KeyNameAbort` | 6 | "ABORT" | - | - |
| `$C3FA` | `RedefineKeysSpare` | 18 | Zero: 18 bytes up to PrintKeyPrompt. Nothing reads or runs them. | - | - |
| `$C40F` | `PressKeyForText` | 21 | PrintInline text: new line, new line, attribute `$46`, "PRESS KEY FOR ", attribute `$45` | - | - |
| `$C42B` | `DefineKeyBlank` | 5 | PrintInline text: two spaces, attribute `$46` | - | - |
| `$C472` | `KeyNameSymShift` | 7 | PrintInline text: "SYM SH" | - | - |
| `$C481` | `KeyNameEnter` | 6 | PrintInline text: "ENTER" | - | - |
| `$C48F` | `KeyNameCapsShift` | 8 | PrintInline text: "CAPS SH" | - | - |
| `$C4A0` | `KeyNameSpace` | 6 | PrintInline text: "SPACE" | - | - |

### music

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C556` | `BassCmd1` | 3 | bass command 1: JP BassGoto (`$C5A7`), the 3-byte entry 1 | - | - |
| `$C568` | `BassCmd7` | 6 | bass commands 7 and 8: JP SetDrumTrack twice (unused, the same as command 3) | - | - |
| `$C575` | `LeadCmd1` | 3 | lead command 1: JP LeadGoto (`$C5B0`) | - | - |
| `$C57B` | `LeadCmd3` | 3 | lead command 3: JP SetDrumTrack, a bass-only handler (it reads HL', the bass track): unusable from the lead track and unused | - | - |
| `$C587` | `LeadCmd7` | 6 | lead commands 7 and 8: JP SetDrumTrack twice (unused) | - | - |
| `$C665` | `DrumTrackSteady` | 5 | drum track: a hiss every 32 frames (32 0, then 1 `$C665`). The drum tracks: records of (frames, kind[, p]) and gotos 1 aa; DrumStep. This one plays at the start and at the end of each pass of the tune; | - | - |
| `$C66A` | `DrumTrackUnused` | 2 | a hiss record (32 0) that no goto reaches | - | - |
| `$C66C` | `DrumTrackBeat` | 12 | drum track: rasp 16, hiss 8, hiss 8, sweep `$30` for 32 frames (64 frames), loops. Started by the bass track's command 3 `$C66C` after the four intro riffs. | - | - |
| `$C678` | `BassTrack` | 69 | the bass track: commands of 3 bytes (drums, pattern calls, the goto back). 3 `$C665`, 4 x 2 `$C6BD` (the riff), 3 `$C66C`, 2 x 2 `$C6CC`, 8 x 2 `$C6DD`, 5 x 2 `$C6CC`, 3 `$C665`, 1 `$C678`: 5120 frames. | - | - |
| `$C6BD` | `BassRiff` | 15 | bass pattern: the 128-frame intro riff on `$7C` with rests, then `$52`. Notes are (period, frames), commands 4 / 5 one byte: `$7C` 16, off, `$7C` 8, on, `$7C` 16, off, `$7C` 64, `$52` 24, on, return. | - | - |
| `$C6CC` | `BassWalk` | 17 | bass pattern: `$7C` `$6E` `$68` `$5D` twice, 64 frames each (512 frames) | - | - |
| `$C6DD` | `BassRun` | 37 | bass pattern: `$7C` in eighths with rests, then the run `$8B` `$93` `$A5` `$BA` `$A5` `$93` `$8B` `$7C` `$8B` `$93` `$A5` (128 frames) | - | - |
| `$C702` | `LeadTrack` | 135 | the lead track: pattern calls, two long notes, the goto back. 4 x riff `$C789`, 4 x phrase `$C7AA`, off, `$C7AA`, on, 5 x `$C7C5`, then `$C7D2` / `$C7C5` three times in turns, `$3E` 32, `$37` 32, 2 x `$C7AA`, 4 x the scale `$C7DF`, 4 x `$C789`, 8 x `$C7C5`, 4 x `$C789`, 1 `$C702`: 5120 frames. | - | - |
| `$C789` | `LeadRiff` | 33 | lead pattern: `$37` with rests, then trills `$29` / `$2E`, `$37`, `$3E` (128 frames) | - | - |
| `$C7AA` | `LeadPhrase` | 27 | lead pattern: the tune's phrase `$29` `$2E` `$31` `$37` `$3E` `$49` `$3E` `$45` `$2E` `$29` `$2E` `$34` `$2E` (256 frames) | - | - |
| `$C7C5` | `LeadArpeggioA` | 13 | lead pattern: `$3E` `$52` `$7C` twice (64 frames) | - | - |
| `$C7D2` | `LeadArpeggioB` | 13 | lead pattern: `$45` `$5D` `$8B` twice (64 frames) | - | - |
| `$C7DF` | `LeadScale` | 65 | lead pattern: the 16-note scale `$29` up to `$BA` (high to low) twice, 4 frames a note (128 frames) | - | - |

### construction

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C8BE` | `ConstructionTitleText` | 31 | PrintInline text: "ROBOT" (double size) at row 0, "CONSTRUCTION" (double height) at row 2. Setting `$22` = double height, double width; `$21` = double height; `$00` = normal (PrintInline code 4: high nibble the height, low nibble the width). | `PrintControl`, `PrintInline` | - |
| `$C8DD` | `PartNamesText` | 85 | PrintInline text: the part names at column 21, ELECTRONICS row 1 down to BIPOD row 22, every 3 rows | `PrintControl`, `PrintInline` | - |
| `$C932` | `ExitStartText` | 24 | PrintInline text: "EXIT START" / "MENU ROBOT" at rows 21-22, columns 5 and 10 | `PrintControl`, `PrintInline` | - |
| `$C94A` | `PartCostsText` | 36 | PrintInline text: the costs under the names at column 22: 3 20 4 4 2 10 5 3 (the same numbers as PartCosts) | `PrintControl`, `PrintInline` | - |
| `$C96E` | `ResourceNamesText` | 121 | PrintInline text: "-- RESOURCES --" / "-- AVAILABLE --", GENERAL row 9, ELECTRONICS-CHASSIS rows 11-16, TOTAL row 18 | `PrintControl`, `PrintInline` | - |
| `$CAF0` | `PartCosts` | 16 | the parts' cost (bipod, tracks, anti-grav, cannon, missiles, phasers, nuclear, electronics), then the resource each takes first (an index into Resources). The second row is the resource index (6 chassis x3, 5 cannon, 4 missiles, 3 phasers, 2 nuclear, 1 electronics; what the own resource lacks comes from general (index 0). | `ConstructionMenuLoop`, `EnemyCommander` | - |
| `$CBFF` | `TotalPosition` | 4 | PrintInline text: AT 18,12 | `PrintControl`, `PrintInline` | - |
| `$CC10` | `MenuResourcePos` | 4 | Inline string: position (row patched, column 13). PrintInline bytes: 1 Y X with Y written by `$CC0A`, then 0 (end). The image holds Y = `$10` from a construction menu run before the block was saved. | `PrintControl`, `PrintInline` | `PrintMenuResource` |

### view

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$CE56` | `BuildingSprites` | 9 | The sprite of each building type. Index = the Buildings type: 0 the player's warbase pad `$2C` (a crate), factories 1 electronics `$28`, 2 nuclear `$25`, 3 phasers `$23`, 4 missiles `$20`, 5 cannon `$1D`, 6 chassis `$17` (each the robot part of its product, facing down: `$16` + the parts table `$D6C8`), 7 and 8 the flags `$2A` and `$2B`. 7 the player's, 8 the enemy's. The bytes: `$2C`, `$28`, `$25`, `$23`, `$20`, `$1D`, `$17`, `$2A`, `$2B`. Read by DrawBuilding. | `DrawCellObject` | - |
| `$CE5F` | `BuildingHeights` | 9 | The height each building sprite is drawn at. Type 0 at `$13`, the six factory signs at `$0F` (on the factory's roof blocks), the flags at `$1A`: the bytes `$13`, `$0F` x 6, `$1A`, `$1A`. Read by DrawBuilding into DrawSprite's height operand. Not the heights the ship lands on: those are BuildingTops (the world module). | `DrawCellObject` | - |

### screen

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$D1C5` | `PlayScreenText` | 32 | Inline string: " DAY:" and "TIME:" at (0,22), the tall "RADAR:" at (22,0). PrintInline bytes: attribute `$17`, position (0,22), size 0, " DAY:", newline, "TIME:", position (22,0), size `$21` (2 rows high, 1 byte wide), attribute `$05`, "RADAR:", 0. White on red for the clock labels, cyan on black for RADAR:, neither BRIGHT. PrintInline returns past the 0 into ShowStatusPanel: DrawPlayScreen has no RET of its own. | `PrintControl`, `PrintInline` | - |
| `$D1EB` | `StatusPanelText` | 168 | Inline string: the STATUS and RESOURCES labels of the right panel. " STATUS" at (3,22) attribute `$06`, "INSG HUMN" (Insignians, the enemy; Humans, the player), then from (6,23) attribute `$05` the rows WARBASES, ELECTR'S, NUCLEAR, PHASERS, MISSILES, CANNON, CHASSIS, ROBOTS; "RESOURCES" at (15,23) attribute `$06` and from row 17 attribute `$04` GENERAL, ELECTR', NUCLEAR, PHASERS, MISSILE, CANNON, CHASSIS: the order of Resources. | `PrintControl`, `PrintInline` | - |
| `$D29B` | `ResourceValuesPos` | 8 | Inline string: position (16,30), attribute `$4E`, size 0. The bytes 1 `$10` `$1E` (position (16,30)), 2 `$4E` (attribute bright yellow on blue), 4 0 (normal size), 0. Row 16: PrintResourceValues starts with a newline. | `PrintControl`, `PrintInline` | - |
| `$D2BB` | `InsgCountsPos` | 6 | Inline string: position (6,22), attribute `$47`. The bytes 1 6 `$16` (position (6,22)), 2 `$47` (bright white on black), 0. | `PrintControl`, `PrintInline` | - |
| `$D2CB` | `PrintHumnCountsPos` | 3 | PrintHumnCountsPos | `PrintControl`, `PrintInline` | - |
| `$D2CE` | `HumnCountsPos` | 4 | Inline string: position (6,31). The bytes 1 6 `$1F` (position (6,31)), 0; the attribute stays `$47`. | `PrintControl`, `PrintInline` | - |
| `$D2DB` | `HumnRobotsPos` | 4 | Inline string: position (13,30). The bytes 1 `$0D` `$1E` (position (13,30)), 0. | `PrintControl`, `PrintInline` | - |
| `$D2F9` | `ClearPanelPos` | 8 | Inline string: position (2,22), size 0, attribute 0. The bytes 1 2 `$16` (position (2,22)), 4 0 (normal size), 2 0 (attribute 0), 0. | `PrintControl`, `PrintInline` | - |
| `$D306` | `PanelBlankLine` | 12 | Inline string: 10 spaces, newline. 10 spaces (columns 22-31), 3 (the next row, the same column), 0. | `PrintInline` | - |

### controls

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$D3CC` | `KeyTable` | 24 | the keys, eight of 3 bytes: the port high byte, the bit mask, the key code (shown by the redefine menu). The bytes as built: F7 01 31 (key 1, Input bit 7, pause), DF 04 49 (I, bit 6, abort), F7 10 35 (5, bit 5, save), 7F 02 82 (SYMBOL SHIFT, bit 4, fire), FB 01 51 (Q, bit 3, up), FD 01 41 (A, bit 2, down), DF 02 4F (O, bit 1, left), DF 01 50 (P, bit 0, right). A key is LD A,(port byte) / IN A,(`$FE`) / AND mask: Z when pressed. The code byte only serves the redefine screen (it prints the key and refuses one already taken). The ninth byte, `$D3E4`, is Controls: 1 in the image (the keyboard only; MainMenu sets 1-3 by the keys 1, 2, 3. | `ReadControls` | - |
| `$D3E4` | `Controls` | 1 | the menu's choice: 1 keyboard, 2 Kempston, 3 Interface 2 | `ReadControls` | - |

### tables

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$D6A8` | `ViewEdgeA` | 16 | View edge, black on the left: 8 lines of 2 bytes. `$FFFF`, `$FFFC`, `$FFF0`... `$C000`: a staircase 2 pixels a line. DrawViewBackground copies it with DrawEdgeStrips (2 bytes a line, 8 lines, then 2 bytes left) 6 times from `$5B0A`, the lower edge of the black triangle above the map, and 3 times from `$5FB2`. Image: d1-img/D6A8-ViewEdges.png. | `DrawEdgeStrips` | - |
| `$D6B8` | `ViewEdgeB` | 16 | View edge, black on the right: 8 lines of 2 bytes. `$0003`, `$000F`... `$FFFF`; DrawViewBackground copies it 4 times from `$6512`: with the 3 copies of ViewEdgeA at `$5FB2` it makes the black band along the map's front edge, bottom right of the view. | `DrawEdgeStrips` | - |
| `$D6C8` | `PartSpriteTable` | 32 | Robot part sprites: 8 parts x 4 directions, sprite id - `$16`. Row = part (bipod, tracks, anti-grav, cannon, missiles, phasers, nuclear, electronics), column = direction (the number of the lowest set bit of robot +`$08`: 0 X+, 1 X-, 2 Y+, 3 Y-). Read by DirectionLoop (`$CF16`; sprite id = byte + `$16`, then DrawSprite) for robots in the view and by ConstructionMenu (`$C87B`; column 1, the odd-column sprite via SpriteTable+`$58`) for the part icons. Bipod, tracks and missiles have one picture per axis, anti-grav and nuclear one for all four. The rows, as sprite ids: bipod `$18`, `$18`, `$19`, `$19`; tracks `$16`, `$16`, `$17`, `$17`; anti-grav `$1A` x 4; cannon `$1B-$1E`; missiles `$1F`, `$1F`, `$20`, `$20`; phasers `$21-$24`; nuclear `$25` x 4; electronics `$26-$29`. Note the part order of the rows (bipod first) against the sprite order (tracks first). | `ConstructionMenu`, `DrawRobotPart` | - |
| `$D6E8` | `SpriteTable` | 204 | Sprite pointers: 51 sprite ids x (even column, odd column). Word = the sprite block for index id x 2 + parity (DrawSprite: AND `$3F`, SRA L / ADC A,A, then TableWord). Ids 0 ship, 1 shadow, 2-18 and 21 map types (2-5 stones, 6-7 boulders, 8-11 rocks, 12-14 trench, 15-18 blocks, 21 post), 19-20 unused (they point at the ship), 22-41 robot parts (PartSpriteTable), 42 the player's flag, 43 the enemy's flag, 44 the warbase sign, 45-50 shots (cannon, missile, phaser; X then Y). ConstructionMenu reads from SpriteTable+`$58` (id 22 on). Read by TableWord (`$D34C`/`$D34E`). | `TableWord` | - |
| `$D7B4` | `PartHeights` | 8 | Height of each robot part in units (bipod `$0B`, tracks 7, anti-grav 8, cannon 6, missiles 6, phasers 7, nuclear 7, electronics 7). Indexed by the part number. DirectionLoop (`$CF28`) adds it to the draw height after each part, so the parts stack; SpawnHeightLoop (`$B911`) sums it over robot +`$07` into +`$09`, the robot's height, when a robot is made. | `DrawRobotPart`, `EnemyCommander` | - |
| `$D7BC` | `TerrainHeights` | 23 | Height of each map cell type (0-22). Indexed by cell AND `$1F`: 0-1 0, stones 2-5 2, boulders 6-7 3, rocks 8-11 6, trench 12-14 0, blocks 15 7, 16 15, 17 7, 18 15, 19-20 0, the post 21 99 (no flight over it), 22 0. Read only by TerrainTop (`$B093`), the height under a cell for CheckShipMove (CellTop) and for shots and robots (GroundUnderFootprint). | `TerrainTop` | - |

## The '98 game (`src/game98`)

Recordings: `work/stage2/game98/deep` (the bot's '98 game, 30284 frames, 9 game days), `work/stage2/game98/play` (r98 4500-5903: the menu, START GAME, play), `work/stage2/game98/key5menu` (the menu, LOAD NEW LEVEL, the menu again, START).

### font

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$6780` | `Font` | 512 | Font: 64 glyphs of 8 bytes, codes `$20-$5F`. Glyph = `$6680` + code * 8, top line first, 1 = ink. Codes `$20-$5F`: space, punctuation, digits, "@" is the (c) sign, A-Z, then "[", "\", "]" and an up arrow at `$5B-$5E`, `$5F` blank. Read by PrintChar (`$D4C2`: 8 lines straight to the screen, one attribute from `$FD13` to the cell at (`$FD14`)) and PrintBigChar (`$D4F5`: each line repeated `$FD16` times; with `$FD17` >= 2 (`$D50C`) each pixel doubled to 16 pixels wide). Every text of the game goes through them (PrintInline and the number printers). Image: d1-img/6780-Font.png. | `PrintBigChar`, `PrintChar`, `PrintControl` | `PutBlock` |

### sprites

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$6980` | `SprTracksX` | 2 | Sprite 22 (even column; SpriteTable 44): tracks, moving along X (directions 0-1), 27 rows x 3 bytes. The sprites run from here to `$A569`, 88 blocks, each reached through SpriteTable (sprite id x 2 + the column parity). A block: the height in pixel lines, the width in bytes, then the rows from the BOTTOM line up, each row width x (mask, graphic) byte pairs: screen = (screen AND mask) OR graphic (SpriteByteLoop into ViewBuffer, DrawMaskedUp straight to the screen). The parity is bit 0 of the half-byte column DrawSprite computes (2 x X + Y - 24): the odd entry is the same picture shifted right by 4 pixels (one byte wider where it needs to), except where noted: for map objects the column parity is the row parity, and map types 12, 13, 14, 17, 18 use the two entries for two different pictures. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawSprite` | `PutBlock` |
| `$6982` | `SprTracksXRows` | 162 | SprTracksX: 27 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | `PutBlock` |
| `$6A24` | `SprTracksXOdd` | 2 | Sprite 22 (odd column; SpriteTable 45): tracks, moving along X (directions 0-1), 27 rows x 4 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. Also the part's icon in ConstructionMenu (`$C86D`, drawn straight to the screen by DrawMaskedUp). | `ConstructionMenu`, `DrawSprite` | `PutBlock` |
| `$6A26` | `SprTracksXOddRows` | 216 | SprTracksXOdd: 27 rows of 4 (mask, graphic) pairs, bottom line first | `DrawMaskedUp`, `DrawSprite` | `PutBlock` |
| `$6AFE` | `SprTracksY` | 2 | Sprite 23 (even column; SpriteTable 46): tracks, moving along Y (directions 2-3), 28 rows x 3 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawSprite` | `PutBlock` |
| `$6B00` | `SprTracksYRows` | 168 | SprTracksY: 28 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | `PutBlock` |
| `$6BA8` | `SprTracksYOdd` | 2 | Sprite 23 (odd column; SpriteTable 47): tracks, moving along Y (directions 2-3), 28 rows x 4 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawSprite` | `PutBlock` |
| `$6BAA` | `SprTracksYOddRows` | 224 | SprTracksYOdd: 28 rows of 4 (mask, graphic) pairs, bottom line first | `DrawSprite` | `PutBlock` |
| `$6C8A` | `SprBipodX` | 2 | Sprite 24 (even column; SpriteTable 48): bipod legs, along X, 30 rows x 3 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawSprite` | `PutBlock` |
| `$6C8C` | `SprBipodXRows` | 180 | SprBipodX: 30 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | `PutBlock` |
| `$6D40` | `SprBipodXOdd` | 2 | Sprite 24 (odd column; SpriteTable 49): bipod legs, along X, 30 rows x 4 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. Also the part's icon in ConstructionMenu (`$C86D`, drawn straight to the screen by DrawMaskedUp). | `ConstructionMenu`, `DrawSprite` | `PutBlock` |
| `$6D42` | `SprBipodXOddRows` | 240 | SprBipodXOdd: 30 rows of 4 (mask, graphic) pairs, bottom line first | `DrawMaskedUp`, `DrawSprite` | `PutBlock` |
| `$6E32` | `SprBipodY` | 2 | Sprite 25 (even column; SpriteTable 50): bipod legs, along Y, 29 rows x 3 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawSprite` | `PutBlock` |
| `$6E34` | `SprBipodYRows` | 174 | SprBipodY: 29 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | `PutBlock` |
| `$6EE2` | `SprBipodYOdd` | 2 | Sprite 25 (odd column; SpriteTable 51): bipod legs, along Y, 29 rows x 4 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawSprite` | `PutBlock` |
| `$6EE4` | `SprBipodYOddRows` | 232 | SprBipodYOdd: 29 rows of 4 (mask, graphic) pairs, bottom line first | `DrawSprite` | `PutBlock` |
| `$6FCC` | `SprAntiGrav` | 2 | Sprite 26 (even column; SpriteTable 52): anti-grav unit, every direction, 23 rows x 3 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawSprite` | `PutBlock` |
| `$6FCE` | `SprAntiGravRows` | 138 | SprAntiGrav: 23 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | `PutBlock` |
| `$7058` | `SprAntiGravOdd` | 2 | Sprite 26 (odd column; SpriteTable 53): anti-grav unit, every direction, 23 rows x 4 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. Also the part's icon in ConstructionMenu (`$C86D`, drawn straight to the screen by DrawMaskedUp). | `ConstructionMenu`, `DrawSprite` | `PutBlock` |
| `$705A` | `SprAntiGravOddRows` | 184 | SprAntiGravOdd: 23 rows of 4 (mask, graphic) pairs, bottom line first | `DrawMaskedUp`, `DrawSprite` | `PutBlock` |
| `$7112` | `SprCannonXp` | 2 | Sprite 27 (even column; SpriteTable 54): cannon facing X+ (direction 0), 28 rows x 3 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawSprite` | `PutBlock` |
| `$7114` | `SprCannonXpRows` | 168 | SprCannonXp: 28 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | `PutBlock` |
| `$71BC` | `SprCannonXpOdd` | 2 | Sprite 27 (odd column; SpriteTable 55): cannon facing X+ (direction 0), 28 rows x 4 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawSprite` | `PutBlock` |
| `$71BE` | `SprCannonXpOddRows` | 224 | SprCannonXpOdd: 28 rows of 4 (mask, graphic) pairs, bottom line first | `DrawSprite` | `PutBlock` |
| `$729E` | `SprCannonXm` | 2 | Sprite 28 (even column; SpriteTable 56): cannon facing X- (direction 1), 30 rows x 3 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawSprite` | `PutBlock` |
| `$72A0` | `SprCannonXmRows` | 180 | SprCannonXm: 30 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | `PutBlock` |
| `$7354` | `SprCannonXmOdd` | 2 | Sprite 28 (odd column; SpriteTable 57): cannon facing X- (direction 1), 30 rows x 4 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. Also the part's icon in ConstructionMenu (`$C86D`, drawn straight to the screen by DrawMaskedUp). | `ConstructionMenu`, `DrawSprite` | `PutBlock` |
| `$7356` | `SprCannonXmOddRows` | 240 | SprCannonXmOdd: 30 rows of 4 (mask, graphic) pairs, bottom line first | `DrawMaskedUp`, `DrawSprite` | `PutBlock` |
| `$7446` | `SprCannonYp` | 2 | Sprite 29 (even column; SpriteTable 58): cannon facing Y+ (direction 2), 30 rows x 3 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawSprite` | `PutBlock` |
| `$7448` | `SprCannonYpRows` | 180 | SprCannonYp: 30 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | `PutBlock` |
| `$74FC` | `SprCannonYpOdd` | 2 | Sprite 29 (odd column; SpriteTable 59): cannon facing Y+ (direction 2), 30 rows x 4 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawSprite` | `PutBlock` |
| `$74FE` | `SprCannonYpOddRows` | 240 | SprCannonYpOdd: 30 rows of 4 (mask, graphic) pairs, bottom line first | `DrawSprite` | `PutBlock` |
| `$75EE` | `SprCannonYm` | 2 | Sprite 30 (even column; SpriteTable 60): cannon facing Y- (direction 3), 25 rows x 3 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawSprite` | `PutBlock` |
| `$75F0` | `SprCannonYmRows` | 150 | SprCannonYm: 25 rows of 3 (mask, graphic) pairs, bottom line first. One byte differs from NE: `$767F`, the third graphic byte of row 23 (the second line from the top), is `$04` (NE `$E0`). With NE's mask `$1F` before it, the three left pixels of that byte turn from ink to paper and one pixel in the see-through part becomes ink over the background (mask 1, graphic 1). | `DrawSprite` | `PutBlock` |
| `$7686` | `SprCannonYmOdd` | 2 | Sprite 30 (odd column; SpriteTable 61): cannon facing Y- (direction 3), 25 rows x 4 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawSprite` | `PutBlock` |
| `$7688` | `SprCannonYmOddRows` | 200 | SprCannonYmOdd: 25 rows of 4 (mask, graphic) pairs, bottom line first | `DrawSprite` | `PutBlock` |
| `$7750` | `SprMissilesX` | 2 | Sprite 31 (even column; SpriteTable 62): missile pod along X, 27 rows x 3 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawSprite` | `PutBlock` |
| `$7752` | `SprMissilesXRows` | 162 | SprMissilesX: 27 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | `PutBlock` |
| `$77F4` | `SprMissilesXOdd` | 2 | Sprite 31 (odd column; SpriteTable 63): missile pod along X, 27 rows x 4 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. Also the part's icon in ConstructionMenu (`$C86D`, drawn straight to the screen by DrawMaskedUp). | `ConstructionMenu`, `DrawSprite` | `PutBlock` |
| `$77F6` | `SprMissilesXOddRows` | 216 | SprMissilesXOdd: 27 rows of 4 (mask, graphic) pairs, bottom line first | `DrawMaskedUp`, `DrawSprite` | `PutBlock` |
| `$78CE` | `SprMissilesY` | 2 | Sprite 32 (even column; SpriteTable 64): missile pod along Y, 28 rows x 3 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawSprite` | `PutBlock` |
| `$78D0` | `SprMissilesYRows` | 168 | SprMissilesY: 28 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | `PutBlock` |
| `$7978` | `SprMissilesYOdd` | 2 | Sprite 32 (odd column; SpriteTable 65): missile pod along Y, 28 rows x 4 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawSprite` | `PutBlock` |
| `$797A` | `SprMissilesYOddRows` | 224 | SprMissilesYOdd: 28 rows of 4 (mask, graphic) pairs, bottom line first | `DrawSprite` | `PutBlock` |
| `$7A5A` | `SprPhasersXp` | 2 | Sprite 33 (even column; SpriteTable 66): phasers facing X+, 28 rows x 3 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | - | `PutBlock` |
| `$7A5C` | `SprPhasersXpRows` | 168 | SprPhasersXp: 28 rows of 3 (mask, graphic) pairs, bottom line first | - | `PutBlock` |
| `$7B04` | `SprPhasersXpOdd` | 2 | Sprite 33 (odd column; SpriteTable 67): phasers facing X+, 28 rows x 4 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | - | `PutBlock` |
| `$7B06` | `SprPhasersXpOddRows` | 224 | SprPhasersXpOdd: 28 rows of 4 (mask, graphic) pairs, bottom line first | - | `PutBlock` |
| `$7BE6` | `SprPhasersXm` | 2 | Sprite 34 (even column; SpriteTable 68): phasers facing X-, 29 rows x 3 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | - | `PutBlock` |
| `$7BE8` | `SprPhasersXmRows` | 174 | SprPhasersXm: 29 rows of 3 (mask, graphic) pairs, bottom line first | - | `PutBlock` |
| `$7C96` | `SprPhasersXmOdd` | 2 | Sprite 34 (odd column; SpriteTable 69): phasers facing X-, 29 rows x 4 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. Also the part's icon in ConstructionMenu (`$C86D`, drawn straight to the screen by DrawMaskedUp). | `ConstructionMenu` | `PutBlock` |
| `$7C98` | `SprPhasersXmOddRows` | 232 | SprPhasersXmOdd: 29 rows of 4 (mask, graphic) pairs, bottom line first | `DrawMaskedUp` | `PutBlock` |
| `$7D80` | `SprPhasersYp` | 2 | Sprite 35 (even column; SpriteTable 70): phasers facing Y+, 29 rows x 3 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | - | `PutBlock` |
| `$7D82` | `SprPhasersYpRows` | 174 | SprPhasersYp: 29 rows of 3 (mask, graphic) pairs, bottom line first | - | `PutBlock` |
| `$7E30` | `SprPhasersYpOdd` | 2 | Sprite 35 (odd column; SpriteTable 71): phasers facing Y+, 29 rows x 4 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | - | `PutBlock` |
| `$7E32` | `SprPhasersYpOddRows` | 232 | SprPhasersYpOdd: 29 rows of 4 (mask, graphic) pairs, bottom line first | - | `PutBlock` |
| `$7F1A` | `SprPhasersYm` | 2 | Sprite 36 (even column; SpriteTable 72): phasers facing Y-, 26 rows x 3 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | - | `PutBlock` |
| `$7F1C` | `SprPhasersYmRows` | 156 | SprPhasersYm: 26 rows of 3 (mask, graphic) pairs, bottom line first | - | `PutBlock` |
| `$7FB8` | `SprPhasersYmOdd` | 2 | Sprite 36 (odd column; SpriteTable 73): phasers facing Y-, 26 rows x 4 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | - | `PutBlock` |
| `$7FBA` | `SprPhasersYmOddRows` | 208 | SprPhasersYmOdd: 26 rows of 4 (mask, graphic) pairs, bottom line first | - | `PutBlock` |
| `$808A` | `SprNuclear` | 2 | Sprite 37 (even column; SpriteTable 74): nuclear bomb (the ball with the trefoil), every direction, 29 rows x 3 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. No recording of NE's drew it. | - | `PutBlock` |
| `$808C` | `SprNuclearRows` | 174 | SprNuclear: 29 rows of 3 (mask, graphic) pairs, bottom line first | - | `PutBlock` |
| `$813A` | `SprNuclearOdd` | 2 | Sprite 37 (odd column; SpriteTable 75): nuclear bomb (the ball with the trefoil), every direction, 29 rows x 4 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. Also the part's icon in ConstructionMenu (`$C86D`, drawn straight to the screen by DrawMaskedUp). | `ConstructionMenu` | `PutBlock` |
| `$813C` | `SprNuclearOddRows` | 232 | SprNuclearOdd: 29 rows of 4 (mask, graphic) pairs, bottom line first | `DrawMaskedUp` | `PutBlock` |
| `$8224` | `SprElectronicsXp` | 2 | Sprite 38 (even column; SpriteTable 76): electronics dome facing X+, 24 rows x 3 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | - | `PutBlock` |
| `$8226` | `SprElectronicsXpRows` | 144 | SprElectronicsXp: 24 rows of 3 (mask, graphic) pairs, bottom line first | - | `PutBlock` |
| `$82B6` | `SprElectronicsXpOdd` | 2 | Sprite 38 (odd column; SpriteTable 77): electronics dome facing X+, 24 rows x 3 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | - | `PutBlock` |
| `$82B8` | `SprElectronicsXpOddRows` | 144 | SprElectronicsXpOdd: 24 rows of 3 (mask, graphic) pairs, bottom line first | - | `PutBlock` |
| `$8348` | `SprElectronicsXm` | 2 | Sprite 39 (even column; SpriteTable 78): electronics dome facing X-, 24 rows x 3 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | - | `PutBlock` |
| `$834A` | `SprElectronicsXmRows` | 144 | SprElectronicsXm: 24 rows of 3 (mask, graphic) pairs, bottom line first. Two graphic bytes differ from NE: `$837F` (row 8, third pair) `$1F`, NE `$80`, and `$8383` (row 9, second pair) `$1C`, NE `$5E`: ZS redrew two lines of the dome's lower half. Under the mask `$7F` at `$837E` the new `$1F` is ink over the background (the leftmost pixel turns from ink to paper); under the mask `$00` at `$8382` the `$1C` is plain ink. The odd-column copy SprElectronicsXmOdd is NE's, so the dome looks slightly different on even and odd columns. | - | `PutBlock` |
| `$83DA` | `SprElectronicsXmOdd` | 2 | Sprite 39 (odd column; SpriteTable 79): electronics dome facing X-, 24 rows x 3 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. Also the part's icon in ConstructionMenu (`$C86D`, drawn straight to the screen by DrawMaskedUp). | `ConstructionMenu` | `PutBlock` |
| `$83DC` | `SprElectronicsXmOddRows` | 144 | SprElectronicsXmOdd: 24 rows of 3 (mask, graphic) pairs, bottom line first | `DrawMaskedUp` | `PutBlock` |
| `$846C` | `SprElectronicsYp` | 2 | Sprite 40 (even column; SpriteTable 80): electronics dome facing Y+, 24 rows x 3 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawSprite` | `PutBlock` |
| `$846E` | `SprElectronicsYpRows` | 144 | SprElectronicsYp: 24 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | `PutBlock` |
| `$84FE` | `SprElectronicsYpOdd` | 2 | Sprite 40 (odd column; SpriteTable 81): electronics dome facing Y+, 24 rows x 3 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawSprite` | `PutBlock` |
| `$8500` | `SprElectronicsYpOddRows` | 144 | SprElectronicsYpOdd: 24 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | `PutBlock` |
| `$8590` | `SprElectronicsYm` | 2 | Sprite 41 (even column; SpriteTable 82): electronics dome facing Y-, 24 rows x 3 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawSprite` | `PutBlock` |
| `$8592` | `SprElectronicsYmRows` | 144 | SprElectronicsYm: 24 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | `PutBlock` |
| `$8622` | `SprElectronicsYmOdd` | 2 | Sprite 41 (odd column; SpriteTable 83): electronics dome facing Y-, 24 rows x 3 bytes. Drawn by DrawRobotPart through DrawSprite for every part of a robot in the view (sprite id = `$16` + PartSpriteTable[part * 4 + direction]), stacked by PartHeights. | `DrawSprite` | `PutBlock` |
| `$8624` | `SprElectronicsYmOddRows` | 144 | SprElectronicsYmOdd: 24 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | `PutBlock` |
| `$86B4` | `SprFlagPlayer` | 2 | Sprite 42 (even column; SpriteTable 84): the player's flag, building type 7, 11 rows x 3 bytes. Drawn by DrawCellObject on a Buildings record of this type, through the table BuildingSprites (sprite id) / BuildingSprites+9 (height). No recording of NE's drew it. | `DrawSprite` | `PutBlock` |
| `$86B6` | `SprFlagPlayerRows` | 66 | SprFlagPlayer: 11 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | `PutBlock` |
| `$86F8` | `SprFlagPlayerOdd` | 2 | Sprite 42 (odd column; SpriteTable 85): the player's flag, building type 7, 11 rows x 4 bytes. Drawn by DrawCellObject on a Buildings record of this type, through the table BuildingSprites (sprite id) / BuildingSprites+9 (height). | `DrawSprite` | `PutBlock` |
| `$86FA` | `SprFlagPlayerOddRows` | 88 | SprFlagPlayerOdd: 11 rows of 4 (mask, graphic) pairs, bottom line first | `DrawSprite` | `PutBlock` |
| `$8752` | `SprFlagEnemy` | 2 | Sprite 43 (even column; SpriteTable 86): the enemy's flag, building type 8, 11 rows x 3 bytes. Drawn by DrawCellObject on a Buildings record of this type, through the table BuildingSprites (sprite id) / BuildingSprites+9 (height). No recording of NE's drew it. | `DrawSprite` | `PutBlock` |
| `$8754` | `SprFlagEnemyRows` | 66 | SprFlagEnemy: 11 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | `PutBlock` |
| `$8796` | `SprFlagEnemyOdd` | 2 | Sprite 43 (odd column; SpriteTable 87): the enemy's flag, building type 8, 11 rows x 4 bytes. Drawn by DrawCellObject on a Buildings record of this type, through the table BuildingSprites (sprite id) / BuildingSprites+9 (height). No recording of NE's drew it. | `DrawSprite` | `PutBlock` |
| `$8798` | `SprFlagEnemyOddRows` | 88 | SprFlagEnemyOdd: 11 rows of 4 (mask, graphic) pairs, bottom line first | `DrawSprite` | `PutBlock` |
| `$87F0` | `SprWarbaseSign` | 2 | Sprite 44 (even column; SpriteTable 88): the warbase sign, building type 0, 17 rows x 3 bytes. Drawn by DrawCellObject on a Buildings record of this type, through the table BuildingSprites (sprite id) / BuildingSprites+9 (height). No recording of NE's drew it. | `DrawSprite` | `PutBlock` |
| `$87F2` | `SprWarbaseSignRows` | 102 | SprWarbaseSign: 17 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | `PutBlock` |
| `$8858` | `SprWarbaseSignOdd` | 2 | Sprite 44 (odd column; SpriteTable 89): the warbase sign, building type 0, 17 rows x 4 bytes. Drawn by DrawCellObject on a Buildings record of this type, through the table BuildingSprites (sprite id) / BuildingSprites+9 (height). | - | `PutBlock` |
| `$885A` | `SprWarbaseSignOddRows` | 136 | SprWarbaseSignOdd: 17 rows of 4 (mask, graphic) pairs, bottom line first | - | `PutBlock` |
| `$88E2` | `SprShotCannonX` | 2 | Sprite 45 (even column; SpriteTable 90): cannon shell, flying along X, 16 rows x 2 bytes. Drawn by DrawMoverSprite for a Shots record: sprite id `$2B` + 2 x weapon + (direction >= 4: flying along Y). No recording of NE's drew it. | - | `PutBlock` |
| `$88E4` | `SprShotCannonXRows` | 64 | SprShotCannonX: 16 rows of 2 (mask, graphic) pairs, bottom line first | - | `PutBlock` |
| `$8924` | `SprShotCannonXOdd` | 2 | Sprite 45 (odd column; SpriteTable 91): cannon shell, flying along X, 16 rows x 2 bytes. Drawn by DrawMoverSprite for a Shots record: sprite id `$2B` + 2 x weapon + (direction >= 4: flying along Y). No recording of NE's drew it. | - | `PutBlock` |
| `$8926` | `SprShotCannonXOddRows` | 64 | SprShotCannonXOdd: 16 rows of 2 (mask, graphic) pairs, bottom line first | - | `PutBlock` |
| `$8966` | `SprShotCannonY` | 2 | Sprite 46 (even column; SpriteTable 92): cannon shell, flying along Y, 13 rows x 3 bytes. Drawn by DrawMoverSprite for a Shots record: sprite id `$2B` + 2 x weapon + (direction >= 4: flying along Y). No recording of NE's drew it. | - | `PutBlock` |
| `$8968` | `SprShotCannonYRows` | 78 | SprShotCannonY: 13 rows of 3 (mask, graphic) pairs, bottom line first | - | `PutBlock` |
| `$89B6` | `SprShotCannonYOdd` | 2 | Sprite 46 (odd column; SpriteTable 93): cannon shell, flying along Y, 13 rows x 3 bytes. Drawn by DrawMoverSprite for a Shots record: sprite id `$2B` + 2 x weapon + (direction >= 4: flying along Y). No recording of NE's drew it. | - | `PutBlock` |
| `$89B8` | `SprShotCannonYOddRows` | 78 | SprShotCannonYOdd: 13 rows of 3 (mask, graphic) pairs, bottom line first | - | `PutBlock` |
| `$8A06` | `SprShotMissileX` | 2 | Sprite 47 (even column; SpriteTable 94): missile, flying along X, 22 rows x 3 bytes. Drawn by DrawMoverSprite for a Shots record: sprite id `$2B` + 2 x weapon + (direction >= 4: flying along Y). No recording of NE's drew it. | - | `PutBlock` |
| `$8A08` | `SprShotMissileXRows` | 132 | SprShotMissileX: 22 rows of 3 (mask, graphic) pairs, bottom line first | - | `PutBlock` |
| `$8A8C` | `SprShotMissileXOdd` | 2 | Sprite 47 (odd column; SpriteTable 95): missile, flying along X, 22 rows x 4 bytes. Drawn by DrawMoverSprite for a Shots record: sprite id `$2B` + 2 x weapon + (direction >= 4: flying along Y). No recording of NE's drew it. | - | `PutBlock` |
| `$8A8E` | `SprShotMissileXOddRows` | 176 | SprShotMissileXOdd: 22 rows of 4 (mask, graphic) pairs, bottom line first | - | `PutBlock` |
| `$8B3E` | `SprShotMissileY` | 2 | Sprite 48 (even column; SpriteTable 96): missile, flying along Y, 22 rows x 3 bytes. Drawn by DrawMoverSprite for a Shots record: sprite id `$2B` + 2 x weapon + (direction >= 4: flying along Y). No recording of NE's drew it. | - | `PutBlock` |
| `$8B40` | `SprShotMissileYRows` | 132 | SprShotMissileY: 22 rows of 3 (mask, graphic) pairs, bottom line first | - | `PutBlock` |
| `$8BC4` | `SprShotMissileYOdd` | 2 | Sprite 48 (odd column; SpriteTable 97): missile, flying along Y, 22 rows x 4 bytes. Drawn by DrawMoverSprite for a Shots record: sprite id `$2B` + 2 x weapon + (direction >= 4: flying along Y). No recording of NE's drew it. | - | `PutBlock` |
| `$8BC6` | `SprShotMissileYOddRows` | 176 | SprShotMissileYOdd: 22 rows of 4 (mask, graphic) pairs, bottom line first | - | `PutBlock` |
| `$8C76` | `SprShotPhaserX` | 2 | Sprite 49 (even column; SpriteTable 98): phaser beam, along X, 17 rows x 3 bytes. Drawn by DrawMoverSprite for a Shots record: sprite id `$2B` + 2 x weapon + (direction >= 4: flying along Y). No recording of NE's drew it. | - | `PutBlock` |
| `$8C78` | `SprShotPhaserXRows` | 102 | SprShotPhaserX: 17 rows of 3 (mask, graphic) pairs, bottom line first | - | `PutBlock` |
| `$8CDE` | `SprShotPhaserXOdd` | 2 | Sprite 49 (odd column; SpriteTable 99): phaser beam, along X, 17 rows x 3 bytes. Drawn by DrawMoverSprite for a Shots record: sprite id `$2B` + 2 x weapon + (direction >= 4: flying along Y). No recording of NE's drew it. | - | `PutBlock` |
| `$8CE0` | `SprShotPhaserXOddRows` | 102 | SprShotPhaserXOdd: 17 rows of 3 (mask, graphic) pairs, bottom line first | - | `PutBlock` |
| `$8D46` | `SprShotPhaserY` | 2 | Sprite 50 (even column; SpriteTable 100): phaser beam, along Y, 20 rows x 3 bytes. Drawn by DrawMoverSprite for a Shots record: sprite id `$2B` + 2 x weapon + (direction >= 4: flying along Y). No recording of NE's drew it. | - | `PutBlock` |
| `$8D48` | `SprShotPhaserYRows` | 120 | SprShotPhaserY: 20 rows of 3 (mask, graphic) pairs, bottom line first | - | `PutBlock` |
| `$8DC0` | `SprShotPhaserYOdd` | 2 | Sprite 50 (odd column; SpriteTable 101): phaser beam, along Y, 20 rows x 3 bytes. Drawn by DrawMoverSprite for a Shots record: sprite id `$2B` + 2 x weapon + (direction >= 4: flying along Y). No recording of NE's drew it. | - | `PutBlock` |
| `$8DC2` | `SprShotPhaserYOddRows` | 120 | SprShotPhaserYOdd: 20 rows of 3 (mask, graphic) pairs, bottom line first | - | `PutBlock` |
| `$8E3A` | `SprShip` | 2 | Sprite 0 (even column; SpriteTable 0, 38, 39, 40, 41): the player's ship, 30 rows x 4 bytes. Drawn by DrawCell / ShipDraw (sprite id 0) at the height Altitude over the ship's cell. | `DrawSprite` | `PutBlock` |
| `$8E3C` | `SprShipRows` | 240 | SprShip: 30 rows of 4 (mask, graphic) pairs, bottom line first | `DrawSprite` | `PutBlock` |
| `$8F2C` | `SprShipOdd` | 2 | Sprite 0 (odd column; SpriteTable 1): the player's ship, 30 rows x 4 bytes. Drawn by DrawCell / ShipDraw (sprite id 0) at the height Altitude over the ship's cell. | `DrawSprite` | `PutBlock` |
| `$8F2E` | `SprShipOddRows` | 240 | SprShipOdd: 30 rows of 4 (mask, graphic) pairs, bottom line first | `DrawSprite` | `PutBlock` |
| `$901E` | `SprShadow` | 2 | Sprite 1 (even column; SpriteTable 2): the ship's shadow on the ground, 24 rows x 3 bytes. Drawn by DrawMapObjects (sprite id 1) at height 0 under the ship, before the map. | `DrawSprite` | `PutBlock` |
| `$9020` | `SprShadowRows` | 144 | SprShadow: 24 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | `PutBlock` |
| `$90B0` | `SprShadowOdd` | 2 | Sprite 1 (odd column; SpriteTable 3): the ship's shadow on the ground, 24 rows x 4 bytes. Drawn by DrawMapObjects (sprite id 1) at height 0 under the ship, before the map. | `DrawSprite` | `PutBlock` |
| `$90B2` | `SprShadowOddRows` | 192 | SprShadowOdd: 24 rows of 4 (mask, graphic) pairs, bottom line first | `DrawSprite` | `PutBlock` |
| `$9172` | `SprStonesA` | 2 | Sprite 2 (both columns; SpriteTable 4, 5): stones, map type 2, 21 rows x 3 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. No recording of NE's drew it. | - | `PutBlock` |
| `$9174` | `SprStonesARows` | 126 | SprStonesA: 21 rows of 3 (mask, graphic) pairs, bottom line first | - | `PutBlock` |
| `$91F2` | `SprStonesB` | 2 | Sprite 3 (both columns; SpriteTable 6, 7): stones, map type 3, 22 rows x 3 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. No recording of NE's drew it. | - | `PutBlock` |
| `$91F4` | `SprStonesBRows` | 132 | SprStonesB: 22 rows of 3 (mask, graphic) pairs, bottom line first | - | `PutBlock` |
| `$9278` | `SprStonesC` | 2 | Sprite 4 (both columns; SpriteTable 8, 9): stones, map type 4, 21 rows x 3 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. No recording of NE's drew it. | - | `PutBlock` |
| `$927A` | `SprStonesCRows` | 126 | SprStonesC: 21 rows of 3 (mask, graphic) pairs, bottom line first | - | `PutBlock` |
| `$92F8` | `SprStonesD` | 2 | Sprite 5 (both columns; SpriteTable 10, 11): stones, map type 5, 20 rows x 3 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. No recording of NE's drew it. | - | `PutBlock` |
| `$92FA` | `SprStonesDRows` | 120 | SprStonesD: 20 rows of 3 (mask, graphic) pairs, bottom line first | - | `PutBlock` |
| `$9372` | `SprRocksA` | 2 | Sprite 8 (both columns; SpriteTable 16, 17): rocks, map type 8, 25 rows x 3 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. No recording of NE's drew it. | `DrawSprite` | `PutBlock` |
| `$9374` | `SprRocksARows` | 150 | SprRocksA: 25 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | `PutBlock` |
| `$940A` | `SprRocksB` | 2 | Sprite 9 (both columns; SpriteTable 18, 19): rocks, map type 9, 26 rows x 3 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. No recording of NE's drew it. | `DrawSprite` | `PutBlock` |
| `$940C` | `SprRocksBRows` | 156 | SprRocksB: 26 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | `PutBlock` |
| `$94A8` | `SprRocksC` | 2 | Sprite 10 (both columns; SpriteTable 20, 21): rocks, map type 10, 23 rows x 3 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. No recording of NE's drew it. | `DrawSprite` | `PutBlock` |
| `$94AA` | `SprRocksCRows` | 138 | SprRocksC: 23 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | `PutBlock` |
| `$9534` | `SprRocksD` | 2 | Sprite 11 (both columns; SpriteTable 22, 23): rocks, map type 11, 24 rows x 3 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. No recording of NE's drew it. | `DrawSprite` | `PutBlock` |
| `$9536` | `SprRocksDRows` | 144 | SprRocksD: 24 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | `PutBlock` |
| `$95C6` | `SprTrenchStartY` | 2 | Sprite 12 (even column; SpriteTable 24): trench start along Y (map type 12 on even rows), 20 rows x 3 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. No recording of NE's drew it. | `DrawSprite` | `PutBlock` |
| `$95C8` | `SprTrenchStartYRows` | 120 | SprTrenchStartY: 20 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | `PutBlock` |
| `$9640` | `SprTrenchStartX` | 2 | Sprite 12 (odd column; SpriteTable 25): trench start along X (map type 12 on odd rows), 21 rows x 4 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. No recording of NE's drew it. | `DrawSprite` | `PutBlock` |
| `$9642` | `SprTrenchStartXRows` | 168 | SprTrenchStartX: 21 rows of 4 (mask, graphic) pairs, bottom line first | `DrawSprite` | `PutBlock` |
| `$96EA` | `SprTrenchMiddleY` | 2 | Sprite 13 (even column; SpriteTable 26): trench middle along Y (map type 13 on even rows), 23 rows x 3 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. No recording of NE's drew it. | `DrawSprite` | `PutBlock` |
| `$96EC` | `SprTrenchMiddleYRows` | 138 | SprTrenchMiddleY: 23 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | `PutBlock` |
| `$9776` | `SprTrenchMiddleX` | 2 | Sprite 13 (odd column; SpriteTable 27): trench middle along X (map type 13 on odd rows), 21 rows x 4 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. No recording of NE's drew it. | `DrawSprite` | `PutBlock` |
| `$9778` | `SprTrenchMiddleXRows` | 168 | SprTrenchMiddleX: 21 rows of 4 (mask, graphic) pairs, bottom line first | `DrawSprite` | `PutBlock` |
| `$9820` | `SprTrenchEndY` | 2 | Sprite 14 (even column; SpriteTable 28): trench end along Y (map type 14 on even rows), 23 rows x 3 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. No recording of NE's drew it. | `DrawSprite` | `PutBlock` |
| `$9822` | `SprTrenchEndYRows` | 138 | SprTrenchEndY: 23 rows of 3 (mask, graphic) pairs, bottom line first. ZS redrew rows 8-15 (36 bytes of `$9856-$987F` differ from NE, masks and graphics): the middle of the trench end has a new shape. Rows 0-7 and 16-22 are NE's. | `DrawSprite` | `PutBlock` |
| `$98AC` | `SprTrenchEndX` | 2 | Sprite 14 (odd column; SpriteTable 29): trench end along X (map type 14 on odd rows), 17 rows x 3 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. No recording of NE's drew it. | `DrawSprite` | `PutBlock` |
| `$98AE` | `SprTrenchEndXRows` | 102 | SprTrenchEndX: 17 rows of 3 (mask, graphic) pairs, bottom line first | `DrawSprite` | `PutBlock` |
| `$9914` | `SprBlockLow` | 2 | Sprite 15 (even column; SpriteTable 30): low block, map type 15, 32 rows x 4 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. | `DrawSprite` | `PutBlock` |
| `$9916` | `SprBlockLowRows` | 256 | SprBlockLow: 32 rows of 4 (mask, graphic) pairs, bottom line first | `DrawSprite` | `PutBlock` |
| `$9A16` | `SprBlockLowOdd` | 2 | Sprite 15 (odd column; SpriteTable 31): low block, map type 15, 32 rows x 4 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. | `DrawSprite` | `PutBlock` |
| `$9A18` | `SprBlockLowOddRows` | 256 | SprBlockLowOdd: 32 rows of 4 (mask, graphic) pairs, bottom line first | `DrawSprite` | `PutBlock` |
| `$9B18` | `SprBlockTall` | 2 | Sprite 16 (even column; SpriteTable 32): tall block with an arch, map type 16, 40 rows x 4 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. | `DrawSprite` | `PutBlock` |
| `$9B1A` | `SprBlockTallRows` | 320 | SprBlockTall: 40 rows of 4 (mask, graphic) pairs, bottom line first | `DrawSprite` | `PutBlock` |
| `$9C5A` | `SprBlockTallOdd` | 2 | Sprite 16 (odd column; SpriteTable 33): tall block with an arch, map type 16, 40 rows x 4 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. | `DrawSprite` | `PutBlock` |
| `$9C5C` | `SprBlockTallOddRows` | 320 | SprBlockTallOdd: 40 rows of 4 (mask, graphic) pairs, bottom line first | `DrawSprite` | `PutBlock` |
| `$9D9C` | `SprBouldersA` | 2 | Sprite 6 (even column; SpriteTable 12): boulders, map type 6, 25 rows x 3 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. No recording of NE's drew it. | - | `PutBlock` |
| `$9D9E` | `SprBouldersARows` | 150 | SprBouldersA: 25 rows of 3 (mask, graphic) pairs, bottom line first | - | `PutBlock` |
| `$9E34` | `SprBouldersAOdd` | 2 | Sprite 6 (odd column; SpriteTable 13): boulders, map type 6, 24 rows x 4 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. No recording of NE's drew it. | - | `PutBlock` |
| `$9E36` | `SprBouldersAOddRows` | 192 | SprBouldersAOdd: 24 rows of 4 (mask, graphic) pairs, bottom line first | - | `PutBlock` |
| `$9EF6` | `SprBouldersB` | 2 | Sprite 7 (even column; SpriteTable 14): boulders, map type 7, 25 rows x 3 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. No recording of NE's drew it. | - | `PutBlock` |
| `$9EF8` | `SprBouldersBRows` | 150 | SprBouldersB: 25 rows of 3 (mask, graphic) pairs, bottom line first | - | `PutBlock` |
| `$9F8E` | `SprBouldersBOdd` | 2 | Sprite 7 (odd column; SpriteTable 15): boulders, map type 7, 24 rows x 4 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. No recording of NE's drew it. | - | `PutBlock` |
| `$9F90` | `SprBouldersBOddRows` | 192 | SprBouldersBOdd: 24 rows of 4 (mask, graphic) pairs, bottom line first | - | `PutBlock` |
| `$A050` | `SprPost` | 2 | Sprite 21 (both columns; SpriteTable 42, 43): border post, map type 21, 36 rows x 2 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. | `DrawSprite` | `PutBlock` |
| `$A052` | `SprPostRows` | 144 | SprPost: 36 rows of 2 (mask, graphic) pairs, bottom line first | `DrawSprite` | `PutBlock` |
| `$A0E2` | `SprBlockDoor` | 2 | Sprite 17 (even column; SpriteTable 34): low block with a door, map type 17 on even rows, 32 rows x 4 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. | - | `PutBlock` |
| `$A0E4` | `SprBlockDoorRows` | 256 | SprBlockDoor: 32 rows of 4 (mask, graphic) pairs, bottom line first | - | `PutBlock` |
| `$A1E4` | `SprBlockWindow` | 2 | Sprite 17 (odd column; SpriteTable 35): low block with a window, map type 17 on odd rows, 32 rows x 4 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. | - | `PutBlock` |
| `$A1E6` | `SprBlockWindowRows` | 256 | SprBlockWindow: 32 rows of 4 (mask, graphic) pairs, bottom line first | - | `PutBlock` |
| `$A2E6` | `SprBlockGrid` | 2 | Sprite 18 (even column; SpriteTable 36): tall block with a grid face and a door, map type 18 on even rows, 40 rows x 4 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. No recording of NE's drew it. | - | `PutBlock` |
| `$A2E8` | `SprBlockGridRows` | 320 | SprBlockGrid: 40 rows of 4 (mask, graphic) pairs, bottom line first | - | `PutBlock` |
| `$A428` | `SprBlockDotted` | 2 | Sprite 18 (odd column; SpriteTable 37): tall block with a dotted face, map type 18 on odd rows, 40 rows x 4 bytes. Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND `$1F`; TerrainHeights gives its height. No recording of NE's drew it. | - | `PutBlock` |
| `$A42A` | `SprBlockDottedRows` | 320 | SprBlockDotted: 40 rows of 4 (mask, graphic) pairs, bottom line first. The top line (row 39, `$A562-$A569`) differs from NE: all four masks are `$00` and the graphics `$00` (NE: masks `$FF` `$FF` `$F7` `$FF`, one graphic `$08`), so the block's top line paints paper over what lies behind it instead of leaving it. | - | `PutBlock` |
| `$A56A` | `SpriteSpare` | 108 | Free space after the sprites (108 zero bytes). Zero, up to ZS's UpgradeEnemyRobots at `$A5D6` (NE: 150 zero bytes up to Start). None of this part's recordings reads or writes it. | - | `PutBlock` |

### robotmenu

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$A738` | `RobotMenuText` | 93 | The robot menu: DIRECT CONTROL, GIVE ORDERS, COMBAT MODE, LEAVE ROBOT, -ORDERS-. A PrintInline string: (4,23) attribute `$4D`, each item two lines of 8 with an empty line between (code 3 = the next line, same column), then (17,23) attribute `$46` "-ORDERS-". | `PrintControl`, `PrintInline` | `PutBlock` |
| `$A7AD` | `OrderLineHead` | 5 | The order line: (18,23), attribute `$45`, then the copied name | `PrintControl`, `PrintInline` | `PutBlock` |
| `$A7B2` | `OrderLine` | 27 | The order's name, 27 bytes copied from OrderNames (DESTROY / ENEMY / ROBOTS in the file). Filled by ShowOrder before each print; the copied name brings its own end byte 0. The '98 file holds DESTROY ENEMY ROBOTS (OrderNames' record of that order) where NE's tape has 27 zeros: the file is the memory after ZS had played, and the robot menu last showed that order. Nothing reads it before ShowOrder writes it again. | `PrintControl`, `PrintInline` | `PutBlock`, `ShowOrder` |
| `$A7D8` | `MilesPos` | 4 | (19,25), the position of the miles | `PrintControl`, `PrintInline` | `PutBlock` |
| `$A820` | `StrengthText` | 19 | "STRENGTH" at (22,23) attribute `$46`, then (23,25) attribute `$47` | `PrintControl`, `PrintInline` | `PutBlock` |
| `$A848` | `OrderNames` | 27 | The names of the orders, 27 bytes each (order 0: STOP AND DEFEND). Nine records of 27 bytes, indexed by +`$0B`: three lines of 8 joined by code 3, ended by 0. ShowOrder copies one into OrderLine. Order 0 is "  STOP  ", "  AND   ", " DEFEND ". | `PrintInline`, `ShowOrder` | `PutBlock` |
| `$A863` | `OrderName1` | 27 | Order 1: ADVANCE (the miles are printed into the blank middle line) | `PrintInline` | `PutBlock` |
| `$A87E` | `OrderName2` | 27 | Order 2: RETREAT (the miles in the middle line) | `PrintInline` | `PutBlock` |
| `$A899` | `OrderName3` | 27 | Order 3: DESTROY ENEMY ROBOTS | `PrintInline`, `ShowOrder` | `PutBlock` |
| `$A8B4` | `OrderName4` | 27 | Order 4: DESTROY ENEMY FACTORYS | `PrintInline` | `PutBlock` |
| `$A8CF` | `OrderName5` | 27 | Order 5: DESTROY ENEMY WARBASES | `PrintInline` | `PutBlock` |
| `$A8EA` | `OrderName6` | 27 | Order 6: CAPTURE NEUTRAL FACTORYS | `PrintInline`, `ShowOrder` | `PutBlock` |
| `$A905` | `OrderName7` | 27 | Order 7: CAPTURE ENEMY FACTORYS | `PrintInline` | `PutBlock` |
| `$A920` | `OrderName8` | 27 | Order 8: CAPTURE ENEMY WARBASES | `PrintInline` | `PutBlock` |
| `$A977` | `OrdersMenuText` | 117 | GIVE ORDERS: SELECT ORDERS and the five items | `PrintControl`, `PrintInline` | `PutBlock` |
| `$AA1F` | `AdvanceTitle` | 14 | "ADVANCE " at (5,23), attribute `$4F` | `PrintInline` | `PutBlock` |
| `$AA32` | `RetreatTitleText` | 14 | "RETREAT " at (5,23), attribute `$4F` | `PrintInline` | `PutBlock` |
| `$AA43` | `DistanceText` | 43 | The distance menu: ?? MILES, SELECT DISTANCE, 0 MILES | `PrintInline` | `PutBlock` |
| `$AAA7` | `DistanceAtText` | 6 | PrintInline: (13,23), attribute `$46`, where the miles are printed | `PrintInline` | `PutBlock` |
| `$AAD8` | `DestroyMenuText` | 101 | SEARCH & DESTROY: SELECT TARGET, ENEMY ROBOTS, FACTORYS, WARBASES | `PrintControl`, `PrintInline` | `PutBlock` |
| `$AB54` | `CaptureMenuText` | 101 | SEARCH & CAPTURE: SELECT TARGET, NEUTRAL FACTORYS, ENEMY FACTORYS, ENEMY WARBASES | `PrintControl`, `PrintInline` | `PutBlock` |
| `$AC06` | `CombatMenuText` | 118 | COMBAT MODE: NUCLEAR BOMB, FIRE PHASERS, FIRE MISSILES, FIRE CANNON, MOVE ROBOT, STOP COMBAT. Printed at (4,23), attribute `$4D`, an item every 3 rows like the robot menu. | - | `PutBlock` |

### gameturn

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$AD88` | `ClockPos` | 8 | The clock: (0,27), setting 0, attribute `$57` | `PrintControl`, `PrintInline` | `PutBlock` |
| `$AE7C` | `LostText` | 51 | "YOU HAVE NO BASES LEFT", "BETTER LUCK NEXT TIME!" at (22,0), attribute `$45` | - | `PutBlock` |
| `$AEB7` | `WonText` | 51 | " WELL DONE! WAIT FOR  ", " NEW LEVELS FROM ZS!  " at (22,0), attribute `$45`. ZS's message in NE's place and length (22 characters a line; NE: " INSIGNIANS DESTROYED " / "    YOU HAVE WON !    "). | - | `PutBlock` |

### ship

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$B0C1` | `BuildingTops` | 9 | The heights of the building types 0-8 for the ship and the robots. Read by ObjectTop with the type byte of the Buildings record: type 0 (the warbase pad) `$0F`, the factory types 1-6 `$16`, `$15`, `$15`, `$16`, `$16`, `$16`, types 7 and 8 `$19`. The pad's 15 is the altitude the ship sinks to on it, where ConstructionMenu opens. | `ObjectTop` | `PutBlock` |

### world

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$B61D` | `StepDelays` | 9 | Game turns a robot step takes: rows flat, low, high ground; columns bipod, tracks, anti-grav. 6 4 3 / 8 6 3 / 9 7 4. Read by SetStepDelay; a game turn is about 10 frames, so a bipod on flat ground steps every 60 frames. | `SetStepDelay` | `PutBlock` |
| `$B6B0` | `LaneSteps` | 8 | The map steps of the four directions: right +1, left -1, down +`$200`, up -`$200`. Read by ScanLane (from LD HL,`$B6AE` and two INC HL a bit of D), in the Input bit order. | `ScanLane` | `PutBlock` |

### level

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$BDA9` | `SceneryWest` | 208 | The scenery of columns 0-255: 66 records (tile or shape, x, y), the 0 that ends them, 9 zero bytes. Read by BuildMap through PlaceScenery with D = 0. Bit 7 clear: a 2 x 2 block of that tile; bit 7 set: shape (byte & `$7F`) of ShapeTable. ZS's list: single blocks only of tiles `$11` (14) and `$12` (26), free-standing blocks of height 7 and 15 that stop every chassis (NE also used the low tiles `$02-$09` and `$0D`); shapes 2, 3, 6, 7, 8, 9. The 0 at `$BE6F` ends it; the 9 zero bytes after it (`$BE70-$BE78`) keep SceneryEast at NE's address and are never read (the level text keeps them as a db line). The tile heights the ship and the robots meet are the table `$D7BC`. | `PlaceScenery` | `MainMenuKeys`, `PutBlock` |
| `$BE79` | `SceneryEast` | 205 | The scenery of columns 256-511: 68 records and the 0 that ends them. Read by BuildMap through PlaceScenery with D = 1 (x + 256). The same record format as SceneryWest: bit 7 clear a 2 x 2 block of that tile (PutBlock), bit 7 set shape (byte AND `$7F`) of ShapeTable. ZS's list: tiles `$07` (2), `$11` (5), `$12` (25); shapes 2-9 (NE also shape 10 and the low tiles). Its two shape 6 records are the fence posts at the right edge, as in NE. | `PlaceScenery` | `MainMenuKeys`, `PutBlock` |
| `$BF46` | `BaseListWest` | 40 | The bases of columns 0-255: 13 records (type, x, y), `$FF` ends. Type 0 a warbase, 1-6 a factory making resource 1-6 (electronics, nuclear, phasers, missiles, cannon, chassis). The '98: the player's warbase at (22,14) and the factories (38,5) type 4, (50,9) 6, (62,13) 1, (74,9) 5, (86,5) 3, (143,5) 2, (143,13) 6, (155,9) 1, (167,3) 3, (167,13) 4, (247,5) 5, (247,13) 6 (NE: the warbase at (22,9), other factories). The (x, y) is the base's door: the cell a robot stands on to capture it (the capture tick `$AD90`) and where the enemy's new robots appear (warbases). | `PlaceBases` | `MainMenuKeys`, `PutBlock` |
| `$BF6E` | `BaseListEast` | 46 | The bases of columns 256-511: 15 records (type, x, y), `$FF` ends. The '98: the enemy's three warbases at (285,10), (412,14), (488,10) (given to the enemy by BuildMap; NE (261,8), (369,8), (494,8)) and twelve factories: (302,3) type 3, (318,3) 1, (334,3) 2, (354,13) 4, (362,11) 6, (368,9) 3, (380,9) 3, (386,11) 5, (394,13) 1, (438,3) 4, (446,3) 5, (454,3) 6. With BaseListWest: 4 warbases and 24 factories (2 nuclear, 5 chassis, 5 phasers, 4 of each other kind), the order of the bases table `$FD70`. Measured as the crow flies or by an anti-grav's walk, 7 factories lie nearer the player's warbase and 17 nearer an enemy one, as in NE. | `PlaceBases` | `MainMenuKeys`, `PutBlock` |
| `$BF9C` | `ShapeTable` | 22 | The shapes' addresses, index 0-10 (DrawShape). 0 the warbase, 1 the factory (both drawn by PlaceBases), 2-10 the scenery shapes (a scenery record `$82-$8A`). | `TableWord` | `MainMenuKeys`, `PutBlock` |
| `$BFB2` | `ShapeWarbase` | 48 | Shape 0: the warbase, 15 blocks of tiles `$0F` (height 7) and `$10` (height 15) around the door. Steps (tile, columns, rows): a first move of (-4,-4), then blocks reaching 4 columns either side and up to 8 rows above the door. The pad, the block above the door at (x, y-4), is a tile `$10` block: altitude 15 over it is the landing height of ConstructionMenu. | `DrawShape` | `PutBlock` |
| `$BFE2` | `ShapeFactory` | 18 | Shape 1: the factory, tiles `$0F` at (x-2, y) and (x+2, y), `$10` on the roof row y-2 at x-2, x, x+2. The door (x, y) stays free between the two low blocks. | `DrawShape` | `PutBlock` |
| `$BFF4` | `ShapeLowTiles` | 36 | Shape 2: 4 x 3 blocks of tiles `$02-$05` (height 2). Steps (tile, dx, dy): 12 blocks in 3 rows of 4, each block 2 cells right of the last, a row 2 cells down (-6, 2); the tiles cycle through the four stone pictures. Drawn by DrawShape for scenery records `$82` (5 placed). Ground height 2: the ship and robots pass over it. | `DrawShape` | `PutBlock` |
| `$C018` | `ShapeMidTiles` | 36 | Shape 3: 4 x 3 blocks of tiles `$08-$0B` (height 6). The rock version of ShapeLowTiles: the same 3 x 4 layout with tiles `$08-$0B` (height 6). Scenery `$83`, 10 placed. | `DrawShape`, `TableWord` | `PutBlock` |
| `$C03C` | `ShapeTallWallV` | 12 | Shape 4: four blocks of tile `$12` (height 15) in a column. Steps of (0, 2): a wall 2 cells thick, 8 rows long, tile `$12` (the tall block). Scenery `$84`, 3 placed. A nuclear blast can turn its blocks to debris. | `DrawShape` | `PutBlock` |
| `$C048` | `ShapeTallWallH` | 12 | Shape 5: four blocks of tile `$12` in a row. Steps of (2, 0): the same wall along X, 8 columns long. Scenery `$85`, 8 placed. | `DrawShape`, `TableWord` | `PutBlock` |
| `$C054` | `ShapeEdgeFence` | 12 | Shape 6: four blocks of tile `$15` (height 99, impassable) in a column: the fences at both ends of the map. Placed at (12,1), (12,9), (503,1), (503,9): the row of posts at the map's left and right edges. | `DrawShape` | `PutBlock` |
| `$C060` | `ShapeFlatLineV` | 12 | Shape 7: tiles `$0C`, `$0D`, `$0D`, `$0E` (height 0) in a column. Steps of (0, 2): a trench along Y: start `$0C`, middle `$0D` twice, end `$0E` (height 0, drawn sunken). Scenery `$87`, 7 placed. | `DrawShape` | `PutBlock` |
| `$C06C` | `ShapeFlatLineH` | 12 | Shape 8: tiles `$0C`, `$0D`, `$0D`, `$0E` in a row. Steps of (2, 0): the same trench along X. Scenery `$88`, 6 placed. | `DrawShape` | `PutBlock` |
| `$C078` | `ShapeLowWallH` | 12 | Shape 9: four blocks of tile `$11` (height 7) in a row. Steps of (2, 0): four low blocks `$11` (height 7) in a row, a wall 8 columns long. Scenery `$89`, 10 placed. | `DrawShape` | `PutBlock` |
| `$C084` | `ShapeMixedWallH` | 9 | Shape 10: tiles `$11`, `$12`, `$11` in a row. Steps of (2, 0): low, tall, low (`$11`, `$12`, `$11`), 6 columns. Scenery `$8A`, 9 placed. | - | `PutBlock` |
| `$C08D` | `MapTablesSpare` | 115 | Unused: zero to `$C0FF`. 115 zero bytes between the level and the main menu (`$C100`); nothing reads or writes them. Room for a longer level description (src/res/game98/map/level.txt may grow into it without moving the code). | - | `PutBlock` |

### mainmenu

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C109` | `MenuStartText` | 23 | "0..START GAME" at (11,8) in double height, yellow. PrintInline codes: attribute `$46`, setting `$21` (double height), position row 11 column 8, the text, setting `$00`. | `PrintControl`, `PrintInline` | `PutBlock` |
| `$C128` | `MenuKeyboardText` | 15 | Three new lines and "1..KEYBOARD" | `PrintControl`, `PrintInline` | `PutBlock` |
| `$C13F` | `MenuKempstonText` | 18 | Two new lines and "2..KEMPSTON J/S" | `PrintControl`, `PrintInline` | `PutBlock` |
| `$C159` | `MenuMoreText` | 57 | "3..INTERFACE 2", then in yellow "4..REDEFINE KEYS", "5..LOAD NEW LEVEL!". ZS's text for option 5 in the place and length of NE's "5..LOAD SAVED GAME": the same 18 characters, the 0 at `$C191` where NE has it. | `PrintControl`, `PrintInline` | `PutBlock` |
| `$C1E6` | `TitleText` | 22 | "ZS EDITION'98 " at (1,2), attribute `$47`, setting `$32` (triple height, double width). ZS's title in the first bytes of NE's two-line "NETHER" / "EARTH": one line of 14 characters, ended by 0 at `$C1FB`, so the RET of PrintTitleEnd stays at `$C1FC`. | `PrintControl`, `PrintInline` | `PutBlock` |
| `$C26A` | `MenuLoadSpare` | 35 | 35 zero bytes: NE's LOADING ERROR! text and LoadError, cleared. `$C26A-$C28C`. Nothing reads or runs them (no recording touched them; no instruction addresses them). | - | `PutBlock` |
| `$C291` | `MenuSaveSpare` | 148 | 148 zero bytes: NE's save prompt, SaveGameBlocks and SaveChecksum, cleared. `$C291-$C324`. Nothing reads or runs them. | - | `PutBlock` |
| `$C31F` | `ChecksumNext` (`MenuSaveSpare`+142) | 6 | carry added into D; the next byte | - | `PutBlock` |
| `$C33F` | `OptionAttrPlain` | 3 | PrintInline: attribute `$46` | `PrintControl`, `PrintInline` | `PutBlock` |
| `$C346` | `OptionAttrChosen` | 3 | PrintInline: attribute `$45` | `PrintControl`, `PrintInline` | `PutBlock` |
| `$C350` | `RedefineTitleText` | 26 | "REDEFINE KEYS" at (2,9), white, double height, then position (5,3) and normal size | - | `PutBlock` |
| `$C382` | `KeyNameUp` | 6 | "   UP" | - | `PutBlock` |
| `$C391` | `KeyNameDown` | 6 | " DOWN" | - | `PutBlock` |
| `$C3A0` | `KeyNameLeft` | 6 | " LEFT" | - | `PutBlock` |
| `$C3AF` | `KeyNameRight` | 6 | "RIGHT" | - | `PutBlock` |
| `$C3BE` | `KeyNameFire` | 6 | " FIRE" | - | `PutBlock` |
| `$C3D0` | `KeyNamePause` | 6 | "PAUSE" | - | `PutBlock` |
| `$C3DF` | `KeyNameAbort` | 6 | "ABORT" | - | `PutBlock` |
| `$C3EE` | `KeyNameSave` | 6 | " SAVE" | - | `PutBlock` |
| `$C40F` | `PressKeyForText` | 21 | PrintInline text: new line, new line, attribute `$46`, "PRESS KEY FOR ", attribute `$45` | - | `PutBlock` |
| `$C42B` | `DefineKeyBlank` | 5 | PrintInline text: two spaces, attribute `$46` | - | `PutBlock` |
| `$C472` | `KeyNameSymShift` | 7 | PrintInline text: "SYM SH" | - | `PutBlock` |
| `$C481` | `KeyNameEnter` | 6 | PrintInline text: "ENTER" | - | `PutBlock` |
| `$C48F` | `KeyNameCapsShift` | 8 | PrintInline text: "CAPS SH" | - | `PutBlock` |
| `$C4A0` | `KeyNameSpace` | 6 | PrintInline text: "SPACE" | - | `PutBlock` |

### music

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C556` | `BassCmd1` | 3 | bass command 1: JP BassGoto (`$C5A7`), the 3-byte entry 1 | - | `PutBlock` |
| `$C568` | `BassCmd7` | 6 | bass commands 7 and 8: JP SetDrumTrack twice (unused, the same as command 3) | - | `PutBlock` |
| `$C575` | `LeadCmd1` | 3 | lead command 1: JP LeadGoto (`$C5B0`) | - | `PutBlock` |
| `$C57B` | `LeadCmd3` | 3 | lead command 3: JP SetDrumTrack, a bass-only handler (it reads HL', the bass track): unusable from the lead track and unused | - | `PutBlock` |
| `$C587` | `LeadCmd7` | 6 | lead commands 7 and 8: JP SetDrumTrack twice (unused) | - | `PutBlock` |
| `$C665` | `DrumTrackSteady` | 5 | drum track: a hiss every 32 frames (32 0, then 1 `$C665`). The drum tracks: records of (frames, kind[, p]) and gotos 1 aa; DrumStep. This one plays at the start and at the end of each pass of the tune; docs r4.md. | `DrumStep` | `PutBlock` |
| `$C66A` | `DrumTrackUnused` | 2 | a hiss record (32 0) that no goto reaches | - | `PutBlock` |
| `$C66C` | `DrumTrackBeat` | 12 | drum track: rasp 16, hiss 8, hiss 8, sweep `$30` for 32 frames (64 frames), loops. Started by the bass track's command 3 `$C66C` after the four intro riffs. | - | `PutBlock` |
| `$C678` | `BassTrack` | 69 | the bass track: commands of 3 bytes (drums, pattern calls, the goto back). 3 `$C665`, 4 x 2 `$C6BD` (the riff), 3 `$C66C`, 2 x 2 `$C6CC`, 8 x 2 `$C6DD`, 5 x 2 `$C6CC`, 3 `$C665`, 1 `$C678`: 5120 frames. | `BassCall`, `BassNextEvent`, `SetDrumTrack` | `PutBlock` |
| `$C6BD` | `BassRiff` | 15 | bass pattern: the 128-frame intro riff on `$7C` with rests, then `$52`. Notes are (period, frames), commands 4 / 5 one byte: `$7C` 16, off, `$7C` 8, on, `$7C` 16, off, `$7C` 64, `$52` 24, on, return. | `BassNextEvent` | `PutBlock` |
| `$C6CC` | `BassWalk` | 17 | bass pattern: `$7C` `$6E` `$68` `$5D` twice, 64 frames each (512 frames) | - | `PutBlock` |
| `$C6DD` | `BassRun` | 37 | bass pattern: `$7C` in eighths with rests, then the run `$8B` `$93` `$A5` `$BA` `$A5` `$93` `$8B` `$7C` `$8B` `$93` `$A5` (128 frames) | - | `PutBlock` |
| `$C702` | `LeadTrack` | 135 | the lead track: pattern calls, two long notes, the goto back. 4 x riff `$C789`, 4 x phrase `$C7AA`, off, `$C7AA`, on, 5 x `$C7C5`, then `$C7D2` / `$C7C5` three times in turns, `$3E` 32, `$37` 32, 2 x `$C7AA`, 4 x the scale `$C7DF`, 4 x `$C789`, 8 x `$C7C5`, 4 x `$C789`, 1 `$C702`: 5120 frames. | `LeadCall`, `LeadNextEvent` | `PutBlock` |
| `$C789` | `LeadRiff` | 33 | lead pattern: `$37` with rests, then trills `$29` / `$2E`, `$37`, `$3E` (128 frames) | `LeadNextEvent` | `PutBlock` |
| `$C7AA` | `LeadPhrase` | 27 | lead pattern: the tune's phrase `$29` `$2E` `$31` `$37` `$3E` `$49` `$3E` `$45` `$2E` `$29` `$2E` `$34` `$2E` (256 frames) | - | `PutBlock` |
| `$C7C5` | `LeadArpeggioA` | 13 | lead pattern: `$3E` `$52` `$7C` twice (64 frames) | - | `PutBlock` |
| `$C7D2` | `LeadArpeggioB` | 13 | lead pattern: `$45` `$5D` `$8B` twice (64 frames) | - | `PutBlock` |
| `$C7DF` | `LeadScale` | 65 | lead pattern: the 16-note scale `$29` up to `$BA` (high to low) twice, 4 frames a note (128 frames) | - | `PutBlock` |

### construction

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C8BE` | `ConstructionTitleText` | 31 | PrintInline text: "ROBOT" (double size) at row 0, "CONSTRUCTION" (double height) at row 2. Setting `$22` = double height, double width; `$21` = double height; `$00` = normal (PrintInline code 4: high nibble the height, low nibble the width). | `PrintControl`, `PrintInline` | `PutBlock` |
| `$C8DD` | `PartNamesText` | 85 | PrintInline text: the part names at column 21, ELECTRONICS row 1 down to BIPOD row 22, every 3 rows | `PrintControl`, `PrintInline` | `PutBlock` |
| `$C932` | `ExitStartText` | 24 | PrintInline text: "EXIT START" / "MENU ROBOT" at rows 21-22, columns 5 and 10 | `PrintControl`, `PrintInline` | `PutBlock` |
| `$C94A` | `PartCostsText` | 36 | PrintInline text: the costs under the names at column 22: 3 20 4 4 2 10 5 3 (the same numbers as PartCosts) | `PrintControl`, `PrintInline` | `PutBlock` |
| `$C96E` | `ResourceNamesText` | 121 | PrintInline text: "-- RESOURCES --" / "-- AVAILABLE --", GENERAL row 9, ELECTRONICS-CHASSIS rows 11-16, TOTAL row 18 | `PrintControl`, `PrintInline` | `PutBlock` |
| `$CAF0` | `PartCosts` | 16 | the parts' cost (bipod, tracks, anti-grav, cannon, missiles, phasers, nuclear, electronics), then the resource each takes first (an index into Resources). The second row is the resource index (6 chassis x3, 5 cannon, 4 missiles, 3 phasers, 2 nuclear, 1 electronics); what the own resource lacks comes from general (index 0). | `ConstructionMenuLoop`, `EnemyCommander` | `PutBlock` |
| `$CBFF` | `TotalPosition` | 4 | PrintInline text: AT 18,12 | `PrintControl`, `PrintInline` | `PutBlock` |
| `$CC10` | `MenuResourcePos` | 4 | Inline string: position (row patched, column 13). PrintInline bytes: 1 Y X with Y written by `$CC0A`, then 0 (end). The file holds Y = `$10` (NE's tape 0): a value PrintMenuResource left when ZS saved the memory after a construction menu; every call writes it before the print. | `PrintControl`, `PrintInline` | `PrintMenuResource`, `PutBlock` |

### view

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$CE56` | `BuildingSprites` | 9 | The sprite of each building type. Index = the Buildings type: 0 the player's warbase pad `$2C` (a crate), factories 1 electronics `$28`, 2 nuclear `$25`, 3 phasers `$23`, 4 missiles `$20`, 5 cannon `$1D`, 6 chassis `$17` (each the robot part of its product, facing down: `$16` + the parts table `$D6C8`), 7 and 8 the flags `$2A` and `$2B`. In NE's deep recording at frame 20000 the type 7 / 8 records stand two columns left of a factory (four of the player's warbase pad): a factory's owner flag; 7 the player's, 8 the enemy's. The bytes: `$2C`, `$28`, `$25`, `$23`, `$20`, `$1D`, `$17`, `$2A`, `$2B`. Read by DrawBuilding. | `DrawCellObject` | `PutBlock` |
| `$CE5F` | `BuildingHeights` | 9 | The height each building sprite is drawn at. Type 0 at `$13`, the six factory signs at `$0F` (on the factory's roof blocks), the flags at `$1A`: the bytes `$13`, `$0F` x 6, `$1A`, `$1A`. Read by DrawBuilding into DrawSprite's height operand. Not the heights the ship lands on: those are BuildingTops (the world module). | `DrawCellObject` | `PutBlock` |

### screen

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$D1C5` | `PlayScreenText` | 32 | Inline string: " DAY:" and "TIME:" at (0,22), the tall "RADAR:" at (22,0). PrintInline bytes: attribute `$17`, position (0,22), size 0, " DAY:", newline, "TIME:", position (22,0), size `$21` (2 rows high, 1 byte wide), attribute `$05`, "RADAR:", 0. White on red for the clock labels, cyan on black for RADAR:, both without NE's BRIGHT (`$57` at `$D1C6` and `$45` at `$D1DD` in NE). PrintInline returns past the 0 into ShowStatusPanel: DrawPlayScreen has no RET of its own. | `PrintControl`, `PrintInline` | `PutBlock` |
| `$D1EB` | `StatusPanelText` | 168 | Inline string: the STATUS and RESOURCES labels of the right panel. "  STATUS" at (3,22) attribute `$06`, "INSG  HUMN" (Insignians, the enemy; Humans, the player), then from (6,23) attribute `$05` the rows WARBASES, ELECTR'S, NUCLEAR, PHASERS, MISSILES, CANNON, CHASSIS, ROBOTS; "RESOURCES" at (15,23) attribute `$06` and from row 17 attribute `$04` GENERAL, ELECTR', NUCLEAR, PHASERS, MISSILE, CANNON, CHASSIS: the order of Resources. ZS cleared BRIGHT in the four attribute bytes (`$D1EF`, `$D207`, `$D24E`, `$D25B`; NE `$46`, `$45`, `$46`, `$44`); the numbers UpdateStatusPanel prints stay bright (`$47`, `$4E`). | `PrintControl`, `PrintInline` | `PutBlock` |
| `$D29B` | `ResourceValuesPos` | 8 | Inline string: position (16,30), attribute `$4E`, size 0. The bytes 1 `$10` `$1E` (position (16,30)), 2 `$4E` (attribute bright yellow on blue), 4 0 (normal size), 0. Row 16: PrintResourceValues starts with a newline. | `PrintControl`, `PrintInline` | `PutBlock` |
| `$D2BB` | `InsgCountsPos` | 6 | Inline string: position (6,22), attribute `$47`. The bytes 1 6 `$16` (position (6,22)), 2 `$47` (bright white on black), 0. | `PrintControl`, `PrintInline` | `PutBlock` |
| `$D2CE` | `HumnCountsPos` | 4 | Inline string: position (6,31). The bytes 1 6 `$1F` (position (6,31)), 0; the attribute stays `$47`. | `PrintControl`, `PrintInline` | `PutBlock` |
| `$D2DB` | `HumnRobotsPos` | 4 | Inline string: position (13,30). The bytes 1 `$0D` `$1E` (position (13,30)), 0. | `PrintControl`, `PrintInline` | `PutBlock` |
| `$D2F9` | `ClearPanelPos` | 8 | Inline string: position (2,22), size 0, attribute 0. The bytes 1 2 `$16` (position (2,22)), 4 0 (normal size), 2 0 (attribute 0), 0. | `PrintControl`, `PrintInline` | `PutBlock` |
| `$D306` | `PanelBlankLine` | 12 | Inline string: 10 spaces, newline. 10 spaces (columns 22-31), 3 (the next row, the same column), 0. | `PrintInline` | `PutBlock` |

### controls

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$D3CC` | `KeyTable` | 24 | the keys, eight of 3 bytes: the port high byte, the bit mask, the key code (shown by the redefine menu). The bytes as built: F7 01 31 (key 1, Input bit 7, pause), DF 04 49 (I, bit 6, abort), F7 10 35 (5, bit 5, save), 7F 02 82 (SYMBOL SHIFT, bit 4, fire), FB 01 51 (Q, bit 3, up), FD 01 41 (A, bit 2, down), DF 02 4F (O, bit 1, left), DF 01 50 (P, bit 0, right). A key is LD A,(port byte) / IN A,(`$FE`) / AND mask: Z when pressed. The code byte only serves the redefine screen (it prints the key and refuses one already taken). The ninth byte, `$D3E4`, is Controls: 1 in the image (the keyboard only); MainMenu sets 1-3 by the keys 1, 2, 3. | `ReadControls` | `PutBlock` |
| `$D3E4` | `Controls` | 1 | the menu's choice: 1 keyboard, 2 Kempston, 3 Interface 2 | `ControlsOptionAttr`, `ReadControls` | `MainMenuKeys`, `PutBlock` |

### tables

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$D6A8` | `ViewEdgeA` | 16 | View edge, black on the left: 8 lines of 2 bytes. `$FFFF`, `$FFFC`, `$FFF0` ... `$C000`: a staircase 2 pixels a line. DrawViewBackground copies it with DrawEdgeStrips (2 bytes a line, 8 lines, then 2 bytes left) 6 times from `$5B0A`, the lower edge of the black triangle above the map, and 3 times from `$5FB2`. Image: d1-img/D6A8-ViewEdges.png. | `DrawEdgeStrips` | `PutBlock` |
| `$D6B8` | `ViewEdgeB` | 16 | View edge, black on the right: 8 lines of 2 bytes. `$0003`, `$000F` ... `$FFFF`; DrawViewBackground copies it 4 times from `$6512`: with the 3 copies of ViewEdgeA at `$5FB2` it makes the black band along the map's front edge, bottom right of the view. | `DrawEdgeStrips` | `PutBlock` |
| `$D6C8` | `PartSpriteTable` | 32 | Robot part sprites: 8 parts x 4 directions, sprite id - `$16`. Row = part (bipod, tracks, anti-grav, cannon, missiles, phasers, nuclear, electronics), column = direction (the number of the lowest set bit of robot +`$08`: 0 X+, 1 X-, 2 Y+, 3 Y-). Read by DirectionLoop (`$CF16`; sprite id = byte + `$16`, then DrawSprite) for robots in the view and by ConstructionMenu (`$C87B`; column 1, the odd-column sprite via SpriteTable+`$58`) for the part icons. Bipod, tracks and missiles have one picture per axis, anti-grav and nuclear one for all four. The rows, as sprite ids: bipod `$18`, `$18`, `$19`, `$19`; tracks `$16`, `$16`, `$17`, `$17`; anti-grav `$1A` x 4; cannon `$1B-$1E`; missiles `$1F`, `$1F`, `$20`, `$20`; phasers `$21-$24`; nuclear `$25` x 4; electronics `$26-$29`. Note the part order of the rows (bipod first) against the sprite order (tracks first). | `ConstructionMenu`, `DrawRobotPart` | `PutBlock` |
| `$D6E8` | `SpriteTable` | 204 | Sprite pointers: 51 sprite ids x (even column, odd column). Word = the sprite block for index id x 2 + parity (DrawSprite: AND `$3F`, SRA L / ADC A,A, then TableWord). Ids 0 ship, 1 shadow, 2-18 and 21 map types (2-5 stones, 6-7 boulders, 8-11 rocks, 12-14 trench, 15-18 blocks, 21 post), 19-20 unused (they point at the ship), 22-41 robot parts (PartSpriteTable), 42 the player's flag, 43 the enemy's flag, 44 the warbase sign, 45-50 shots (cannon, missile, phaser; X then Y). ConstructionMenu reads from SpriteTable+`$58` (id 22 on). Read by TableWord (`$D34C`/`$D34E`). | `TableWord` | `PutBlock` |
| `$D7B4` | `PartHeights` | 8 | Height of each robot part in units (bipod `$0B`, tracks 7, anti-grav 8, cannon 6, missiles 6, phasers 7, nuclear 7, electronics 7). Indexed by the part number. DirectionLoop (`$CF28`) adds it to the draw height after each part, so the parts stack; SpawnHeightLoop (`$B911`) sums it over robot +`$07` into +`$09`, the robot's height, when a robot is made. | `DrawRobotPart`, `EnemyCommander` | `PutBlock` |
| `$D7BC` | `TerrainHeights` | 23 | Height of each map cell type (0-22). Indexed by cell AND `$1F`: 0-1 0, stones 2-5 2, boulders 6-7 3, rocks 8-11 6, trench 12-14 0, blocks 15 7, 16 15, 17 7, 18 15, 19-20 0, the post 21 99 (no flight over it), 22 0. Read only by TerrainTop (`$B093`), the height under a cell for CheckShipMove (CellTop) and for shots and robots (GroundUnderFootprint). | `TerrainTop` | `PutBlock` |

### worldstate

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$D7D3` | `Shots` | 45 | Shots in flight: 5 records of 9 bytes. +0/+1 the map cell (+1 = 0: free), +2/+3 X, +4 Y, +5 the direction (bit 0 X+2, 1 X-2, 2 Y+2, 3 Y-2), +6 steps left (5, 7 for missiles, 1 more with electronics), +7 the weapon (1 cannon, 2 missiles, 3 phasers: a random one of the robot's weapon bits 3-5), +8 the flight height (`$0A`: a cell at least that high stops it). FindFreeShot gives a robot a free slot of two: the player's at `$D7DC` / `$D7E5`, the enemy's at `$D7EE` / `$D7F7`; the first record `$D7D3` is the player's COMBAT MODE shot, fired by CombatFireShot when it is free (FindFreeShot never hands it out). FireShot fires, UpdateShot (from WorldTurn, every turn) moves and hits, DrawCellObject / DrawMoverSprite draw. Cleared by the start-up (`$A661`). Zero in the file. | `FindFreeShot`, `FireShot`, `MoveShot`, `NewGameSetup`, `Start` +2 | `FireShot`, `MoveShot`, `NewGameSetup`, `PutBlock`, `ShotGone` +2 |
| `$D800` | `RadarOwn` | 128 | Radar bitmap with the player's robots: 16 lines of 16 bytes. One pixel line per map row, one bit per map column, 128 columns from the radar's left edge (`$FD1C`, moved by 64 columns at a time). BuildRadar builds it (a bit is set where cell AND `$1F` >= `$0F`: blocks and posts), copies it to RadarEnemy, then ToggleRadarDot XORs a 2-line marker for every robot into the player's or the enemy's copy by the side bit of +`$0A` (also when a robot moves, PlaceRobot / RobotStep). PlayInterrupt shows the two copies on alternate frames (`$FD1A`) with ShowRadar at `$50C6` (16 lines, 16 bytes) and attributes `$4D` / `$4E` in rows 22-23, so each side's robots blink in their own colour. Cleared with the map by BuildMap (`$BC87`). The file holds zeros for rows 0-7 (`$D800-$D87F`), the last bytes of its last sector; rows 8-15 lie past the file. | `BuildMap`, `BuildRadar`, `ShowRadar`, `ToggleRadarDot` | `BuildMap`, `BuildRadar`, `PutBlock`, `ToggleRadarDot` |

## The '98 intro (`src/intro98`)

Recordings: `work/stage2/intro98/w-intro` (r98's intro window).

### pt3player

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C00B` | `PlayerId` | 33 | " PT 3 Player v1.0 by Nick of GDC " (33 bytes, never read) | - | - |
| `$C0A0` | `SamplePtrs` | 64 | 32 sample pointers (module address added by InitModule); at a page offset `$A0`: the decoders index .... 32 sample pointers (module address added by InitModule); at a page offset `$A0`: the decoders index it by the low byte | `ChAOrnSampleCmd`, `ChASampleCmd`, `ChBOrnSampleCmd`, `ChCOrnSampleCmd`, `ChCSampleCmd` +1 | `Pt3Init` |
| `$C0E0` | `OrnamentPtrs` | 32 | 16 ornament pointers, right after the samples (page offset `$E0`). 16 ornament pointers, right after the samples (page offset `$E0`) | `ChAOrnSampleCmd`, `ChAOrnamentCmd`, `ChBOrnSampleCmd`, `ChBOrnamentCmd`, `ChCOrnSampleCmd` +1 | `Pt3Init` |
| `$C100` | `VolumeTable` | 256 | 16 x 16 bytes at a page start: [channel volume * 16 + sample level] -> the AY volume (3.3x-3.4x form). 16 x 16 bytes at a page start: [channel volume * 16 + sample level] -> the AY volume. Pro Tracker 3.3x-3.4x's form of Ivan Roshin's table (row v, column l: 0 for v = 0, else l * (v + 1) / 16 rounded down; row 1 = 0 x 8, 1 x 8; row 2 = 0 x 6, 1 x 5, 2 x 5), written by the tracker for this 3.3 module; the signature's copy holds the 3.5x+ form (50 of the 256 bytes differ). Its first byte (0) is also the "end of pattern" InitState points channel A at. | `Pt3Play`, `WriteAy` | - |
| `$C200` | `NoteTable` | 192 | 96 tone periods (words, notes C-1 .. B-8 of the tracker), at a page start: PT3's tone table #1 .... 96 tone periods (words, notes C-1 .. B-8 of the tracker), at a page start: PT3's tone table #1 (Sound Tracker's, `$0EF8` for the lowest note), the only one this player has. The effect tables follow it in the same page (the decoders index them by the low byte). | - | - |
| `$C2C0` | `ChAEffects` | 54 | The effect routines of the three channels, effects 1-9 (6 and 7 unused: `$0052`, a RET in the 48 K .... The effect routines of the three channels, effects 1-9 (6 and 7 unused: `$0052`, a RET in the 48 K ROM). | `ChADecodeByte` | - |
| `$C2D2` | `ChBEffects` (`ChAEffects`+18) | 18 | - | - | - |
| `$C2E4` | `ChCEffects` (`ChAEffects`+36) | 18 | - | - | - |
| `$C2F6` | `AyPad` | 10 | "-VORONEZH-": 10 bytes up to the page start the AY block needs, never read. The text "-VORONEZH-" (the town of the player's authors, Nick of GDC: "Golden Disk, Voronezh" in ANE's source of the player; who put it here is not known; ANE's copy holds zeros here). WriteAy needs the AY block at a page start, so these bytes are padding: no code reads or writes them (none in the window). | - | - |
| `$C300` | `AyToneA` | 14 | The AY block, at a page start (WriteAy uses L as the register number): registers 0-12. The AY block, at a page start (WriteAy uses L as the register number): registers 0-12. | `WriteAy` | `Pt3Play`, `Pt3Stop` |
| `$C302` | `AyToneB` (`AyToneA`+2) | 2 | - | `WriteAy` | `Pt3Play` |
| `$C304` | `AyToneC` (`AyToneA`+4) | 2 | - | `WriteAy` | `Pt3Play` |
| `$C306` | `AyUnused` (`AyToneA`+6) | 2 | registers 6 and 7: WriteAy takes IXH and IXL instead | - | - |
| `$C308` | `AyVolumeA` (`AyToneA`+8) | 1 | - | `WriteAy` | `Pt3Play`, `Pt3Stop` |
| `$C309` | `AyVolumeB` (`AyToneA`+9) | 1 | - | `WriteAy` | `Pt3Play`, `Pt3Stop` |
| `$C30A` | `AyVolumeC` (`AyToneA`+10) | 1 | - | `WriteAy` | `Pt3Play`, `Pt3Stop` |
| `$C30B` | `AyEnvPeriod` (`AyToneA`+11) | 2 | - | `WriteAy` | `Pt3Play` |
| `$C30D` | `AyEnvTypeUnused` (`AyToneA`+13) | 1 | register 13: written from EnvType, not from here | - | - |

### pt3tune

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$CE21` | `Pt3Module` | 2670 | the module: src/res/intro98/cool-winter.pt3. COOL WINTER by KLIM of OHG (Omega Hackers Group, named in the scroller's greetings), 1997, as Pro Tracker 3.3 compiled it. Read only by the player (InitModule and the decoders through the pointers it sets up). | `ChADecodeByte`, `ChAEffPorta`, `ChAEnvCmd`, `ChAOrnSampleCmd`, `ChBDecodeByte` +8 | - |

### introtext

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$DAC2` | `ScrollText` | 2295 | the scroller text (src/res/intro98/scroll-text.txt). Signed "ZS. 23.12.1998": Sergey Zotov's greetings, the story of the edition, what he changed in the game, his phone and e-mail, the greetings; it ends with "Нажмите что-нибудь..." (press something), from ScrollTextLoop on again and again. | `ScrollStep` | - |

### intrologo

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$E3B9` | `LogoMask` | 64 | the ZS logo: 8 x 8 cells, 1 = painted (src/res/intro98/logo.png). Read by LogoColour every frame: row by row, the cells of the block at column 12, row 0 that take the colour. | `LogoColour` | - |
| `$E3F9` | `RobotHeader` | 5 | the robot box: column 13, row 16, 6 x 8 cells, attribute 6. Column 13, row 16, width 6, height 8 cells, attribute 6 (yellow ink on black): exactly the box RobotStream draws into (tools/intro98_res.py decodes every write of it inside that box) and the colour IntroMain gives the bottom third. Nothing reads these bytes (no read in the window): the header the picture's packer put in front of its depacker, kept with it. | - | - |

### robot

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$E4B3` | `RobotStream` | 537 | the four frames (src/res/intro98/robot.png, robot.parse). 537 bytes: frame 1 (the whole robot, 303 bytes written), frames 2-4 (the changes, 78-80 bytes each); each frame skips `$1342` positions first (four skips of 1023 and one of 838 or 922) to reach the box. Read by RobotFrame only (the window read all of it, `$E4B3-$E6CB`). | `RobotSelf` | - |

### introfont

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$E6CC` | `IntroFont` | 768 | the scroller's font: 96 glyphs from code `$20` (src/res/intro98/font.png). 8 x 8 glyphs for `$20-$7F`: digits and signs as ASCII, `$40-$5F` upper-case and `$60-$7F` lower-case Cyrillic in the KOI-7 N2 order (ЮАБЦДЕФГХИЙКЛМНОПЯРСТУЖВЬЫЗШЭЩЧЪ). ScrollStep's font until the text switches to the ROM's (`$3D00`) and back; glyph = IntroFont - 256 + code * 8. | `ScrollStep` | - |
| `$E9CC` | `FontTailLeftover` | 52 | 52 bytes after the font that nothing reads (src/res/intro98/font-tail-leftover.bin). The end of the block's last sector after the font: no code reads them (no read in the window) and nothing addresses them. Kept as a leftover resource; what they were is not known (they look like a table of 3-byte records: 3 7 0 / 3 7 0 ... 4 7 0 ...). | - | - |

## The '99 stage 2: the intro (`src/stage2`)

Recordings: `work/stage2/front99/intro` (r99's intro window).

### effects

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$631F` | `RollInSource` | 2 | RollInPicture's picture address | `RollInPicture` | `RollInPicture` |

### print

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$651D` | `PrintCol` | 6 | The print column, 0-63 | `PrintChar`, `PrintNewRow` | `PrintChar`, `PrintNewRow` |
| `$651E` | `PrintRow` (`PrintCol`+1) | 1 | the print row, 0-23 (more: not drawn) | `PrintChar`, `PrintNewRow` | `PrintChar`, `PrintNewRow` |
| `$651F` | `PrintArgsLeft` (`PrintCol`+2) | 1 | the argument bytes still to come after `$16` or `$17` | `PrintChar` | `PrintChar` |
| `$6520` | `PrintCode` (`PrintCol`+3) | 1 | the control code waiting for its arguments (`$16` or `$17`) | `PrintChar` | `PrintChar` |
| `$6521` | `PrintCurrent` (`PrintCol`+4) | 1 | the byte being printed | `PrintChar` | `PrintChar` |
| `$6522` | `PrintMask` (`PrintCol`+5) | 1 | `$F0` (even column) or `$0F` (odd) | `PrintChar` | `PrintChar` |
| `$6523` | `PrintFont` | 2 | The font: glyph row r of character c at PrintFont + c + 256 x r (Font64 once IntroMain set it; on the disk `$3C00`, the ROM's font, which is not in this layout) | `PrintChar` | `IntroMain` |

### texts

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$6547` | `ScrollWindow` | 4 | The scroller's window: column 16, row 17, 16 bytes wide, 6 rows high. Read by ScrollWindowUp through IX (+0 column, +1 row, +2 width in bytes, +3 height in character rows): the screen's right half, rows 17-22, under the logo's box. | `ScrollWindowUp` | - |
| `$654B` | `ScrollWindowPad` | 1 | A byte no code reads (`$00`) | - | - |
| `$654C` | `ScrollText` | 4155 | The scroller's text: AT 32,22, then 157 lines of CP866 text, each ending CR LF. 4155 bytes, `$654C-$7586`. Its first three bytes are AT 32,22 (`$16` `$20` `$16`), which PrintLine prints before every line; the text itself starts with them too. The lines are Russian (CP866) with Latin names and TAB indents: ZS's greeting, the story of the Edition, thanks (M.M.A.) and the date 28.01.1999, ending "Нажмите пробел..." (press space). The recording (r99) scrolled the first 23 lines. The source is src/res/stage2/scroller.txt (UTF-8). | `PrintChars`, `PrintLine` | - |
| `$7587` | `Font64` | 2048 | The 64-column font: 256 characters x 8 rows, row-major (row r of character c at Font64 + 256 x r + c). CP866 glyphs 4 pixels wide, each drawn in both nibbles of its bytes (PrintChar keeps the half for the column). Characters `$00-$1F` are never printed (codes below `$20` are control codes), their bytes are there all the same. 2048 bytes, `$7587-$7D86`, the block's last. The source is src/res/stage2/font64.png. | `PrintChar` | - |

## The '99 pictures block (`src/pictures99`)

Recordings: `work/stage2/front99/intro` (r99's intro window).

### picture

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$7DFA` | `PackedScreen` | 3132 | The intro's screen, RLE-packed (3132 bytes): the author's photo, the logo, the bottom line. 6912 bytes once decoded: on the left the photo of Sergey Zotov (ZS) in black on white; on the right in a red frame the logo "NETHER EARTH / ZS / EDITION / 1999" (green, magenta, cyan), "ZS" under it; on the bottom row "You wanted new levels? Take its!" in yellow. 429 runs (`$9A` V N), one of them a `$9A` literal; the stream ends at `$8A35`, the decoder's run counter back at 0. The source is src/res/pictures99/intro-screen.png; the build packs it (tools/front99_res.py) into these bytes. | `DecodeScreen` | - |
| `$8A36` | `SectorSlack` | 81 | The 81 bytes after the packed screen to the end of the 13th sector: no code reads them. RLE bytes of another picture (runs of `$00` and of `$3F` / `$F0`, not this screen's tail), left in the memory the block was saved from. Kept as a leftover (src/res/pictures99/leftover-8a36.bin). | - | - |

## The '99 music block (`src/music99`)

Recordings: `work/stage2/front99/intro` (r99's intro window).

### player

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C000` | `CompileHeader` | 11 | Eleven bytes the compiler leaves in front of the jumps. `$0B` `$00` `$0E` `$00`: the offsets of the init and play entries (`$C00B`, `$C00E`) as words; `$7E` `$80` `$81` `$80` `$80` `$10` `$1F`: bytes no code of the block reads (the compiler's own; their meaning is not known from this block). Nothing in the recording reads any of them. | - | - |
| `$C00D` | `InitPad` | 1 | A padding byte after the JR (NOP) | - | - |
| `$C010` | `PlayPad` | 1 | A padding byte after the JR (NOP) | - | - |
| `$C013` | `MutePad` | 1 | A padding byte after the JR (NOP) | - | - |
| `$C014` | `CompileText` | 56 | "SOUND TRACKER COMPILATION OF NE___MUS   BY KSA SOFTWARE" and the byte `$7F`. The compiler's signature with the module name ("NE___MUS") and the author field ("KSA SOFTWARE") filled in when compiling: other compiled blocks carry their own (the reference copy "SLIDE" with an empty author, "BURO NAHOD BY WILLIS SOFT"). Whether KSA Software is the musician or the author field of the copy of Sound Tracker used is not known from this block. `$7F` at `$C04B` ends it. | - | - |
| `$C0C9` | `PositionsAddr` | 8 | The module's position list (past its count byte). The player's variables, `$C0C9-$C107`. Before Init they hold the compiler's leftovers (as on the disk); InitModule sets them. | `NextPosition`, `ReadRow`, `SetOrnament` | `InitModule` |
| `$C0CB` | `OrnamentsAddr` (`PositionsAddr`+2) | 2 | the module's ornaments | `SetOrnament` | `InitModule` |
| `$C0CD` | `PatternsAddr` (`PositionsAddr`+4) | 2 | the module's pattern table | `NextPosition` | `InitModule` |
| `$C0CF` | `SamplesAddr` (`PositionsAddr`+6) | 2 | the module's samples (module + 27) | `ReadRow` | `InitModule` |
| `$C0D1` | `Tempo` | 3 | Frames a row (the module's first byte) | `NextPosition`, `PlayFrame` | `InitModule`, `PlayFrame` |
| `$C0D2` | `DelayCounter` (`Tempo`+1) | 1 | frames left until the next row | `PlayFrame` | `InitModule`, `PlayFrame` |
| `$C0D3` | `PositionCount` (`Tempo`+2) | 1 | the number of positions (list byte + 1) | `NextPosition` | `InitModule` |
| `$C0D4` | `PatternPtrA` | 6 | Channel A's pattern stream: the next row's byte | `PlayFrame` | `InitModule`, `NextPosition`, `PlayFrame` |
| `$C0D6` | `PatternPtrB` (`PatternPtrA`+2) | 2 | channel B's pattern stream | `PlayFrame` | `NextPosition`, `PlayFrame` |
| `$C0D8` | `PatternPtrC` (`PatternPtrA`+4) | 2 | channel C's pattern stream | `PlayFrame` | `NextPosition`, `PlayFrame` |
| `$C0DA` | `PatternEnd` | 1 | `$FF`: channel A's stream points here after Init (an end of pattern: the first Play fetches a position) | `PlayFrame` | - |
| `$C0DB` | `ChannelState` | 30 | Channel A's 10 bytes; IX points at +2 (ChannelA). Per channel (A `$C0DB`, B `$C0E5`, C `$C0EF`), IX = the channel + 2: IX-2 the envelope state (0 none, 1 set by the row, 2 written once), IX-1 the row length reload, IX+0 the sample line (0-31), IX+1 the note, IX+2 the rows left until the next note, IX+3/4 the sample's address, IX+5/6 the ornament's address, IX+7 the sample lines left (`$FF`: silent). | `EnvelopeFlag`, `InitModule`, `PlayFrameOut`, `RowCountdown`, `SampleStep` +1 | `ChannelOff`, `InitModule`, `ReadRow`, `RowCountdown`, `SampleStep` +1 |
| `$C0DD` | `ChannelA` (`ChannelState`+2) | 8 | channel A: IX here | `EnvelopeFlag`, `InitModule`, `PlayFrameOut`, `RowCountdown`, `SampleStep` +1 | `InitModule`, `ReadRow`, `RowCountdown`, `SampleStep`, `SetOrnament` |
| `$C0E5` | `ChannelStateB` (`ChannelState`+10) | 2 | channel B's 10 bytes | `EnvelopeFlag`, `InitModule`, `RowCountdown` | `InitModule`, `ReadRow`, `SetOrnament` |
| `$C0E7` | `ChannelB` (`ChannelState`+12) | 8 | channel B: IX here | `EnvelopeFlag`, `InitModule`, `PlayFrameOut`, `RowCountdown`, `SampleStep` +1 | `InitModule`, `ReadRow`, `RowCountdown`, `SampleStep`, `SetOrnament` |
| `$C0EF` | `ChannelStateC` (`ChannelState`+20) | 2 | channel C's 10 bytes | `EnvelopeFlag`, `InitModule`, `RowCountdown` | `InitModule`, `ReadRow`, `SetOrnament` |
| `$C0F1` | `ChannelC` (`ChannelState`+22) | 8 | channel C: IX here | `EnvelopeFlag`, `InitModule`, `PlayFrameOut`, `RowCountdown`, `SampleStep` +1 | `ChannelOff`, `InitModule`, `ReadRow`, `RowCountdown`, `SampleStep` +1 |
| `$C0F9` | `PositionIndex` | 1 | The next position to play | `InitModule`, `NextPosition` | `InitModule`, `NextPosition` |
| `$C0FA` | `AYTone` | 6 | The AY registers 0-13 as WriteAY writes them (down from 13 or 10): tone A, B, C periods | `InitModule`, `WriteAY` | `InitModule`, `PlayFrameOut` |
| `$C100` | `AYNoise` | 8 | Register 6: the noise period | `InitModule`, `PlayFrameOut`, `WriteAY` | `InitModule`, `NoiseFromSample`, `PlayFrameOut` |
| `$C101` | `AYMixer` (`AYNoise`+1) | 1 | register 7: the mixer | `InitModule`, `PlayFrameOut`, `WriteAY` | `InitModule`, `PlayFrameOut` |
| `$C102` | `AYVolume` (`AYNoise`+2) | 3 | registers 8-10: the volumes A, B, C (bit 4: the envelope) | `InitModule`, `WriteAY` | `InitModule`, `PlayFrameOut` |
| `$C105` | `AYEnvPeriod` (`AYNoise`+5) | 2 | registers 11-12: the envelope period | `InitModule` | `InitModule` |
| `$C107` | `AYEnvShape` (`AYNoise`+7) | 1 | register 13: the envelope shape (0: not written this frame) | `WriteAY` | `InitModule` |
| `$C3B8` | `NoteTable` | 192 | The 96 tone periods of the notes (8 octaves of 12, `$0EF8` down to `$000F`). The AY tone period of each note (the Sound Tracker table, for the AY's 1.77 MHz clock). | `TonePeriod` | - |
| `$C4A8` | `Module` | 2023 | The tune: an STC module (Sound Tracker compiled, 2023 bytes). Its 27-byte header: tempo 6, positions at +`$026D`, ornaments at +`$0292`, patterns at +`$0358`, the identifier "SONG BY ST COMPILE", the size `$07E7`; then 16 samples of 99 bytes, the 18 positions, the ornaments, the pattern table and the patterns. The source is the .stc file (src/res/music99/ne_mus.stc, readable by zxtune and other STC players). | `FindNumbered`, `InitModule`, `NextPosition`, `PlayFrame`, `ReadOffset` +4 | - |
| `$CC8F` | `SectorSlack` | 113 | The 113 bytes after the module to the end of the 13th sector: no code reads them. They look like the end of another tune's patterns (the same kind of bytes as the module's pattern data) left in the memory the block was saved from. Kept as a leftover (src/res/music99/leftover-cc8f.bin). | - | - |

## The '99 stage 3: System checking (`src/stage3`)

Recordings: `work/stage2/menu99/r99-s3a` (r99 2194-2300), `work/stage2/menu99/r99-s3b` (r99 2299-2662), `work/stage2/menu99/s99-s3` (the Scorpion), `work/stage2/menu99/r48-s3` (the 48 K path).

### s3data

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$6633` | `PageListGuard` | 1 | `$FF` in front of PageList (no window reads it) | - | - |
| `$6634` | `PageList` | 63 | the pages to count: 0 1 3 4 6 7 8 .. 63, `$FF`. The 62 pages 0-63 without 2 and 5 (the fixed pages at `$8000` and `$4000`), `$FF` at `$6672`. CountPages removes the aliases in place. | `CountPages` | `CountPages` |
| `$6673` | `PageSave` | 64 | the byte at `$C000` of pages 0-63 while CountPages marks them | `CountPages` | `CountPages` |
| `$66B3` | `TitleText` | 76 | AT 0,10 INK 4 PAPER 0 FLASH 0 BRIGHT 0 "NETHER  EARTH" AT 1,10 "ZS Edition'99" INK 6 AT 3,1 "System checking..." CR "Computer " INK 5 | `PrintFF` | - |
| `$66FF` | `MemoryText` | 13 | CR INK 6 "Memory " INK 5 | `PrintFF` | - |
| `$670C` | `KbText` | 14 | INK 6 "Kb" CR "Using " INK 5 | `PrintFF` | - |
| `$671A` | `TapeRecorderText` | 14 | "TAPE RECORDER" (the tape path; no window reads it) | - | - |
| `$6728` | `LoadingText` | 26 | AT 8,1 INK 6 "Loading... " CR "Game... " | `PrintFF` | - |
| `$6742` | `OkText` | 10 | INK 4 "O.k." INK 6 CR | `PrintFF` | - |
| `$674C` | `DriversText` | 12 | "Drivers... " | `PrintFF` | - |
| `$6758` | `MenusText` | 10 | "Menus... " | `PrintFF` | - |
| `$6762` | `RamDiskText` | 13 | "RAM-Disk... " | `PrintFF` | - |
| `$676F` | `BattleText` | 27 | AT 20,5 INK 0 "Let the Battle begin!": nothing prints it. No code of stage 3, the game, the patches or the menu block names `$676F` (byte search); its tail from `$6780` is the game block's once loaded. | - | - |
| `$6780` | `GameBlock` (`BattleText`+17) | 10 | the game block's first byte once read (ReadSectors, 68 sectors): its entry | - | - |
| `$678A` | `TapeErrorText` | 38 | AT 20,3 INK 2 PAPER 6 BRIGHT 1 FLASH 1 "Tape Error. System Halted." | - | - |
| `$67B0` | `MachineNames` | 60 | `$FF`, then "Scorpion" "Spectrum" "Spectrum" "ATM" "TURBO 2+" "PROFI" "KAY" "Spectrum": bits 7-0. SkipStrings from the `$FF` at `$67B0`: the B-th string is the name of bit 8-B. Bit 6 is never set; bits 5 and 0 are both "Spectrum", NameDefault is used for scheme 0. | `PrintFF`, `SkipStrings` | - |
| `$67B1` | `NameScorpion` (`MachineNames`+1) | 50 | - | `PrintFF`, `SkipStrings` | - |
| `$67E3` | `NameDefault` (`MachineNames`+51) | 9 | - | `PrintFF` | - |

## The '99 start-up menu (`src/menu99`)

Recordings: `work/stage2/menu99/r99-menu` (r99 2661-6462), `work/stage2/menu99/m99-menu1` (every item), `work/stage2/menu99/m99-menu4` (REDEFINE).

### menumain

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$D826` | `MenuText` | 236 | the menu's upper part through PrintInline (src/res/menu99/menu-strings.txt [menu]) | - | - |
| `$D920` | `MenuBottomText` | 71 | the six items of rows 17 and 21 (menu-strings.txt [bottom]) | - | - |
| `$DAE6` | `LevelPatches` | 36 | the bytes StartGame copies: EASY (the game's own), then MEDIUM and HARD. Six pieces copied in order: 3 bytes to SpawnResources, 6 to InsgRobotCount, 9 to EnemyProduce (EASY), then 3 and 6 (MEDIUM up) and 9 (HARD up). | `MenuRedraw` | - |
| `$DAE9` | `PatchEasyInsg` (`LevelPatches`+3) | 6 | CALL `$D3EC` (PrintNumber2Zero), CALL PrintInline | `MenuRedraw` | - |
| `$DAEF` | `PatchEasyProduce` (`LevelPatches`+9) | 9 | LD HL,`$FD4A`, LD DE,`$FD42`, CALL `$AE4E` (ProduceSide) | `MenuRedraw` | - |
| `$DAF8` | `PatchSpawn99` (`LevelPatches`+18) | 3 | CALL `$A5F2`: the enemy's resources 99 (game99's part) | `MenuRedraw` | - |
| `$DAFB` | `PatchInsgHidden` (`LevelPatches`+21) | 6 | NOP, CALL PrintInline, "??" over the first two bytes of the game's inline text | `MenuRedraw` | - |
| `$DB01` | `PatchProduceUpgrade` (`LevelPatches`+27) | 9 | six NOPs, CALL `$A5D6`: EnemyUpgrade over the enemy robots (game99's part) | `MenuRedraw` | - |
| `$DB2B` | `DescTitle` | 34 | "NETHER EARTH" / "DESCRIPTION" (menu-strings.txt [description]) | - | - |
| `$DB5B` | `AboutTitle` | 36 | "NETHER EARTH" / "ZS EDITION'99" (menu-strings.txt [about]) | - | - |
| `$DB97` | `AdvicesTitle` | 30 | "NETHER EARTH" / "ADVICES" (menu-strings.txt [advices]) | - | - |
| `$DBC3` | `GreetsTitle` | 29 | "NETHER EARTH" / "GREETS" (menu-strings.txt [greets]) | - | - |

### menuviewer

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$DC7D` | `ViewerHeader` | 6 | AT 0,8 then the font: `$16` 0 8, `$17` ViewerFont | `PrintCount` | - |
| `$DD5A` | `ViewerCol` | 1 | the column 0-63 | `ViewerPutChar` | `ViewerPutChar` |
| `$DD5B` | `ViewerRow` | 1 | the row 0-23 (24: the page is full) | `TextViewer`, `ViewerPutChar` | `ViewerPutChar` |
| `$DD5C` | `ViewerParams` | 1 | parameters still to come | `ViewerPutChar` | `ViewerPutChar` |
| `$DD5D` | `ViewerCode` | 1 | the control they belong to | `ViewerPutChar` | `ViewerPutChar` |
| `$DD5E` | `ViewerChar` | 1 | the byte being printed | `ViewerPutChar` | `ViewerPutChar` |
| `$DD5F` | `ViewerMask` | 1 | the half of the cell: `$F0` or `$0F` | `ViewerPutChar` | `ViewerPutChar` |
| `$DD60` | `ViewerFontPtr` | 2 | the font (`$3C00` in the image; the header sets ViewerFont) | `ViewerPutChar` | `ViewerPutChar` |

### menupointer

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$DE11` | `PointerSprite` | 16 | 8 rows of mask, pixels: the arrow (src/res/menu99/pointer.png) | `DrawPointer` | - |
| `$DE21` | `PointerBg` | 16 | the 16 screen bytes under the pointer | `SetPointerBgWay` | `SetPointerBgWay` |
| `$DE31` | `SavedAttrs` | 192 | the attributes of rows 10-15 as MenuBottom found them (192 bytes) | `MenuRedraw` | `MenuBottom` |
| `$DEF1` | `ViewerFont` | 2048 | the 64-column font, 8 planes of 256 (src/res/menu99/viewer-font.png) | `ViewerPutChar` | - |
| `$E6F1` | `TextStart` | 3 | 0, CR, LF: the stop in front of TextBuffer for the viewer's Q | `TextViewer` | - |

## The '99 patches block: `diskread` (`src/patches99`)

Recordings: `work/stage2/game99/r99-play` (the start-up menu, LOAD MAP, HARD + PHASERS, play), `work/stage2/game99/loadmap-menu` (LOAD MAP: the catalogue and a map loaded).

No data entries.

## The '99 patches block: `diskmap` (`src/patches99`)

Recordings: `work/stage2/game99/r99-play` (the start-up menu, LOAD MAP, HARD + PHASERS, play), `work/stage2/game99/loadmap-menu` (LOAD MAP: the catalogue and a map loaded).

### diskmap

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C216` | `DiskListPos` | 8 | Inline string: position (0,0), attribute `$01`, setting `$11`, end. The bytes 1 0 0 (position (0,0)), 2 `$01` (blue on black), 4 `$11` (single size), 0. | - | - |

## The '99 patches block: `paging128` (`src/patches99`)

Recordings: `work/stage2/game99/r99-play` (the start-up menu, LOAD MAP, HARD + PHASERS, play), `work/stage2/game99/loadmap-menu` (LOAD MAP: the catalogue and a map loaded).

No data entries.

## The '99 patches block: `menu128` (`src/patches99`)

Recordings: `work/stage2/game99/r99-play` (the start-up menu, LOAD MAP, HARD + PHASERS, play), `work/stage2/game99/loadmap-menu` (LOAD MAP: the catalogue and a map loaded).

### menu128

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C123` | `MenuGap128` | 1 | Zero: never run | - | - |
| `$C158` | `MenuStub` | 39 | Code copied to `$6700` and run there (bytes here: the copy reads them): page 1's `$D800-$E7FF` into page 0 through the screen, then RET into the menu. Runs at `$6700` with the stack at `$6780` (below the game block, above the stub): page 1 in, 4 K from `$D800` to the screen `$4000-$4FFF` (its pixels: the picture on the screen is lost, the menu redraws it), page 0, the 4 K back to `$D800`, then the caller's stack (the operand at `$C179`, written by ShowMenu128) with `$D800` pushed and the ROM's LDIR; RET: the menu starts, and its last RET goes where ShowMenu128's caller returns. Only absolute addresses, so it runs at `$6700` as it is. | - | `MenuTable128`, `ShowMenu128` |

## The '99 patches block: `taperead` (`src/patches99`)

Recordings: `work/stage2/game99/r99-play` (the start-up menu, LOAD MAP, HARD + PHASERS, play), `work/stage2/game99/loadmap-menu` (LOAD MAP: the catalogue and a map loaded).

### taperead

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$A5AC` | `TapeErrorText` | 29 | PrintInline text: "ERROR! LOAD AGAIN... " at (11,5), attribute `$42`, setting `$21`. The bytes 1 11 5 (position (11,5)), 2 `$42` (bright red on black), 4 `$21` (double height), the 21 characters, 0. | - | - |
| `$A5CC` | `TapeReadSpare` | 10 | Zero: 4 bytes of the piece never used | - | - |

## The '99 patches block: `tapemap` (`src/patches99`)

Recordings: `work/stage2/game99/r99-play` (the start-up menu, LOAD MAP, HARD + PHASERS, play), `work/stage2/game99/loadmap-menu` (LOAD MAP: the catalogue and a map loaded).

### tapemap

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C20A` | `TapeWaitText` | 29 | PrintInline text: "WAITING FOR LEVELFILE" at (11,5), attribute `$05`, setting `$21`. The bytes 1 11 5 (position (11,5)), 2 `$05` (cyan on black), 4 `$21` (double height), the 21 characters, 0. | - | - |
| `$C235` | `TapeLoadedText` | 19 | PrintInline text: "LOADED O.K." at (11,5), attribute `$05`, setting `$22`. The bytes 1 11 5 (position (11,5)), 2 `$05`, 4 `$22` (double height, double width), the 11 characters, 0. | - | - |

## The '99 patches block: `textload48` (`src/patches99`)

Recordings: `work/stage2/game99/r99-play` (the start-up menu, LOAD MAP, HARD + PHASERS, play), `work/stage2/game99/loadmap-menu` (LOAD MAP: the catalogue and a map loaded).

### textload48

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$A57B` | `WaitFileText` | 22 | PrintInline text: "WAITING FILE n" at (11,8), attribute `$06`, setting `$21`. The bytes 1 11 8 (position (11,8)), 2 `$06` (yellow on black), 4 `$21` (double height), "WAITING FILE " and the digit LoadText writes at `$A58F`, 0. | - | - |
| `$A58F` | `WaitFileDigit` (`WaitFileText`+20) | 2 | the file's digit (LoadText writes it) | - | - |

## The '99 patches block: `menu48` (`src/patches99`)

Recordings: `work/stage2/game99/r99-play` (the start-up menu, LOAD MAP, HARD + PHASERS, play), `work/stage2/game99/loadmap-menu` (LOAD MAP: the catalogue and a map loaded).

No data entries.
