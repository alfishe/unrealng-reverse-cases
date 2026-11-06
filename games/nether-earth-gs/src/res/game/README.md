# The game image's resources

The data of `neart001` that is not code: the font, the 89 sprite blocks, the view's edge patterns, the level (the
scenery and base lists BuildMap turns into the map at each new game, with the shape table and the shapes), Nether
Earth's menu tune (still in the file and still read, silent here: `src/game/music.asm`) and the order names. They are
Nether Earth's bytes at Nether Earth's addresses, so the formats and the tables below are those of
`../nether-earth/src/res/README.md`, with this case's one difference: the last byte of the dotted block sprite
(`$A569`) is also the first instruction of `GsMenuSound` (below).

Each is kept in an editable source here; `tools/res_formats.py` turns the sources into the original `.bin` files
under `build/game/res`, and `tools/build_game.sh` assembles `src/game/game.asm` twice with `INCBIN` from there
(sjasmplus, `build/game` and `src/game` on the include path): `neart001` of the disk and, with `-DHOOD_TAPE`, of
Hood's tape, each compared byte for byte with the original. Any edit shows at once as a difference.

- **Where they come from.** An entry of `src/game/game.ann` followed by `@res FILE` is a resource: `kit/mkgame.py`
  (through `kit/mkgame.py --install`) writes its bytes to `FILE` and its data lines in `src/game/*.asm`
  become `INCBIN "res/FILE",offset,length` under the entry's label and description. Entries that name one file share
  it: a sprite's header and rows entries, the two view edges, the nine order names. The install goes through
  `res_formats.install`: every file here is an editable source, no `.bin` is kept. Edit the sources, not the `.asm`.
- **What stays in the source.** Tables of addresses that name labels (`SpriteTable` `$D6E8`), small tables the code
  reads field by field (`PartSpriteTable`, `PartHeights`, `TerrainHeights`, `BuildingSprites`, `PartCosts`,
  `KeyTable`, `StepDelays`), the inline strings of the menus and panels (`DEFM` after a `CALL PrintInline`), the
  buffers and work space (`ViewBufferTail`, the radar, `Shots`, `Robots`, `Map`, `workspace.asm`: zero or leftovers
  of the conversion's memory dump) and `SpriteSpare` (the 87 zero bytes after the GS bridge).
- **The overlap.** `gfx/sprites/block-dotted.png` holds the whole sprite as the game draws it (322 bytes,
  `$A428-$A569`), but `$A569` is also the `DI` (`$F3`) that starts `GsMenuSound`: the conversion put its code in the
  zero bytes after the sprite and started one byte early (in Nether Earth that byte is 0). It is the graphic byte of
  the top line's rightmost pair, whose mask is `$FF`: the game draws `(screen AND $FF) OR $F3`, six ink pixels
  (`11110011`) over whatever lies behind, at the top right of every dotted block (map type 18 on odd rows). In the PNG
  they are palette index 3, ink over the background. The built `.bin` stops one byte short (321 bytes,
  `res_formats.OVERLAP`); the PNG's last pixel byte must be `$F3` or the build refuses it.
- **Checked against the recording.** No byte of any file here is written in this case's recording `work/stage2/r1`
  (the `byte_counts` writes of its `l1.json`: none for all 121 files; it starts at the main menu, after the load).
- **Commands.**

```sh
python3 tools/res_formats.py build --out build/game/res   # the sources -> the .bin files the source INCBINs
python3 tools/res_formats.py check                         # each source built, written back out, built again: same bytes
python3 tools/res_formats.py export --from DIR             # .bin files (as mkgame writes them in OUT/res) -> sources here
python3 tools/res_formats.py --res DIR check               # the same on a copy of src/res/game
```

Sizes may change: a sprite's PNG size is its header, the level and the tune are laid out section after section from
their first address and their labels (the shape table, the gotos and calls) follow. A change of size moves everything
after it in the image, so the build is no longer the original; the code reaches everything by label, except the two
fixed bases below.

- `ShowOrder` finds a name at `OrderNames - 27 + 27 x (order + 1)` (written `StrengthText+$000D`), and the order
  names stay 27 bytes each (`res_formats` refuses other lengths).
- `PrintChar` / `PrintBigChar` take a glyph at `Font - $100 + 8 x code` (written `ViewBuffer+$0B80`): the font
  stays at `$6780` as long as the view buffer before it keeps its size.

## Formats

| Format | Layout |
| --- | --- |
| **Font PNG** (`gfx/font.png`) | 128 x 32: 64 glyphs of 8 x 8, 16 a row, in code order from `$20`. Palette: 0 paper, 1 ink. The `.bin` is 8 bytes a glyph, one byte a pixel line from the top, bit 7 the leftmost pixel. Codes `$20-$5F`: `@` is the (c) sign, `$5B-$5E` are `[ \ ]` and an up arrow, `$5F` is a line along the bottom. |
| **Sprite PNG** (`gfx/sprites/*.png`) | One block, upright, as wide as its bytes x 8 and as tall as its lines. The `.bin`: byte 0 the lines, byte 1 the width in bytes, then the rows from the BOTTOM line up, each `width` pairs (mask, graphic); a pixel is `(screen AND mask) OR graphic` (DrawSprite `$CF2D`, DrawMaskedUp `$D315`). The PNG's size is the header. Palette: 0 see-through (mask 1, graphic 0), 1 paper (mask 0, graphic 0), 2 ink (mask 0, graphic 1), 3 ink over the background (mask 1, graphic 1: the same on the screen as ink, but other bytes; the image has 3 such bytes: `$71A6` mask `$01` graphic `$27` in cannon-xp, `$7282` `$1F`/`$70` in cannon-xp-odd, `$7676` `$E0`/`$3B` in cannon-ym). Ink is black in the view, paper its light colour. |
| **View edges PNG** (`gfx/view-edges.png`) | 32 x 8: ViewEdgeA (left 16 pixels: black on the left) and ViewEdgeB (right 16: black on the right). Palette 0 paper, 1 ink. The `.bin`: per pattern 8 lines of 2 bytes, top line first, left byte first; DrawViewBackground `$CFD7` copies them with DrawEdgeStrips `$D057` (2 bytes a line down the buffer, 8 lines a strip, each strip 2 bytes left of the last). |
| **Level text** (`map/level.txt`) | The sections `scenery SceneryWest`, `scenery SceneryEast`, `bases BaseListWest`, `bases BaseListEast`, `table ShapeTable`, then `shape ShapeWarbase` ... `shape ShapeMixedWallH` (11), in this order from `$BDA9`. Scenery (PlaceScenery): `block TILE x y` (record tile, x low, y: a 2 x 2 block, PutBlock), `shape N x y` (record `$80+N`: ShapeTable entry N through DrawShape), `end` (0). Bases (PlaceBases): `warbase x y` (type 0), `factory T x y` (T 1-6, the resource it makes: 1 electronics, 2 nuclear, 3 phasers, 4 missiles, 5 cannon, 6 chassis), `end` (`$FF`). A column x is written 0-511: the West lists hold 0-255 (D = 0), the East lists 256-511 (D = 1), the file keeps the low byte. Table: `dw Label`, the shape of each index. Shape (DrawShape `$BD61`, also walked by MarkBaseDestroyed `$BC1C` with debris tiles): 3-byte steps (tile, dx, dy): `block TILE move DX DY`, `move DX DY` (tile 0: no block), `block TILE end` / `end` (the step whose move is (0, 0) ends the shape after its block). `db` / `dw` write bytes as they are. |
| **Menu tune text** (`music/menu.txt`) | The sections `drums DrumTrackSteady`, `drums DrumTrackUnused`, `drums DrumTrackBeat`, `voice BassTrack`, `voice BassRiff`, `voice BassWalk`, `voice BassRun`, `voice LeadTrack`, `voice LeadRiff`, `voice LeadPhrase`, `voice LeadArpeggioA`, `voice LeadArpeggioB`, `voice LeadScale`, in this order from `$C665`. Drums (DrumStep `$C5DB`): `hiss N` (N kind 0: 96 ROM bytes to the beeper in Nether Earth), `rasp N` (kind 1, or `rasp N K` for another kind but 0 / 2: 80 ROM bytes with a growing gap), `sweep N P` (kind 2 P: a falling tone), `goto Label` (1 aa); N the frames to the next record. Voice (BassNextEvent `$C528`, LeadNextEvent `$C53B`): `note P N` (period P >= 9, N frames), `goto Label` (1), `call Label` (2: a pattern, one level), `drums Label` (3: the drum continues at Label; bass only), `on` (4), `off` (5: silent, notes keep their time), `return` (6). Commands 0, 7, 8 (unused) only as `db`. Frames are interrupts (1/50 s); in Nether Earth a period P sounded at about 3.5 MHz / (125.5 x P), here the beeper writes are NOPs and the tune is silent (`src/game/music.asm`). |
| **Order names text** (`text/order-names.txt`) | `N "line 1" "line 2" "line 3"`, orders 0-8 (robot `+$0B`), each line exactly 8 characters of the font. The `.bin`: 27 bytes an order, the three lines joined by code 3 (next line) and ended by 0, copied by ShowOrder into OrderLine `$A7B2` and printed by PrintInline. |

## Files

All addresses are where the bytes sit in the game image (`neart001`, `$6590-$FFFF`, as the loaders leave it). The
entries are the labels of `src/game/game.ann` that carry `@res`.

| Source | Builds | Address | Bytes | Entries | Read by |
| --- | --- | --- | ---: | --- | --- |
| `gfx/font.png` | `gfx/font.bin` | `$6780-$697F` | 512 | `Font` | PrintChar `$D4B1`, PrintBigChar `$D4DA` |
| `gfx/sprites/*.png` (89) | `gfx/sprites/*.bin` | `$6980-$A569` | 15 338 (`$A569` shared with code) | `Spr*`, `Spr*Rows` (table below) | DrawSprite `$CF2D` through SpriteTable `$D6E8`; the construction menu's part icons through DrawMaskedUp `$D315` |
| `gfx/view-edges.png` | `gfx/view-edges.bin` | `$D6A8-$D6C7` | 32 | `ViewEdgeA`, `ViewEdgeB` | DrawViewBackground `$CFD7`, DrawEdgeStrips `$D057` |
| `text/order-names.txt` | `text/order-names.bin` | `$A848-$A93A` | 243 | `OrderNames`, `OrderName1`-`OrderName8` | ShowOrder `$A795` (copies one into OrderLine `$A7B2`) |
| `map/level.txt` | `map/scenery-west.bin` | `$BDA9-$BE78` | 208 | `SceneryWest` | BuildMap `$BC6F` / PlaceScenery `$BCD6`, D = 0: 69 records |
| | `map/scenery-east.bin` | `$BE79-$BF45` | 205 | `SceneryEast` | the same, D = 1: 68 records |
| | `map/bases-west.bin` | `$BF46-$BF6D` | 40 | `BaseListWest` | PlaceBases `$BCF9`: the player's warbase and 12 factories |
| | `map/bases-east.bin` | `$BF6E-$BF9B` | 46 | `BaseListEast` | PlaceBases: the enemy's 3 warbases and 12 factories |
| | `map/shape-table.bin` | `$BF9C-$BFB1` | 22 | `ShapeTable` | DrawShape `$BD61` (11 words) |
| | `map/shapes/warbase.bin` | `$BFB2-$BFE1` | 48 | `ShapeWarbase` | shape 0, PlaceBases type 0 |
| | `map/shapes/factory.bin` | `$BFE2-$BFF3` | 18 | `ShapeFactory` | shape 1, PlaceBases types 1-6 |
| | `map/shapes/low-tiles.bin` | `$BFF4-$C017` | 36 | `ShapeLowTiles` | shape 2 (scenery `$82`) |
| | `map/shapes/mid-tiles.bin` | `$C018-$C03B` | 36 | `ShapeMidTiles` | shape 3 |
| | `map/shapes/tall-wall-v.bin` | `$C03C-$C047` | 12 | `ShapeTallWallV` | shape 4 |
| | `map/shapes/tall-wall-h.bin` | `$C048-$C053` | 12 | `ShapeTallWallH` | shape 5 |
| | `map/shapes/edge-fence.bin` | `$C054-$C05F` | 12 | `ShapeEdgeFence` | shape 6 |
| | `map/shapes/flat-line-v.bin` | `$C060-$C06B` | 12 | `ShapeFlatLineV` | shape 7 |
| | `map/shapes/flat-line-h.bin` | `$C06C-$C077` | 12 | `ShapeFlatLineH` | shape 8 |
| | `map/shapes/low-wall-h.bin` | `$C078-$C083` | 12 | `ShapeLowWallH` | shape 9 |
| | `map/shapes/mixed-wall-h.bin` | `$C084-$C08C` | 9 | `ShapeMixedWallH` | shape 10 |
| `music/menu.txt` | `music/menu/drum-steady.bin` | `$C665-$C669` | 5 | `DrumTrackSteady` | DrumStep `$C5DB` (MenuMusic `$C4A7` starts it) |
| | `music/menu/drum-unused.bin` | `$C66A-$C66B` | 2 | `DrumTrackUnused` | none: no goto reaches it |
| | `music/menu/drum-beat.bin` | `$C66C-$C677` | 12 | `DrumTrackBeat` | DrumStep, from the bass track's `drums` |
| | `music/menu/bass-track.bin` | `$C678-$C6BC` | 69 | `BassTrack` | BassNextEvent `$C528` |
| | `music/menu/bass-riff.bin` | `$C6BD-$C6CB` | 15 | `BassRiff` | the same (call) |
| | `music/menu/bass-walk.bin` | `$C6CC-$C6DC` | 17 | `BassWalk` | the same (call) |
| | `music/menu/bass-run.bin` | `$C6DD-$C701` | 37 | `BassRun` | the same (call) |
| | `music/menu/lead-track.bin` | `$C702-$C788` | 135 | `LeadTrack` | LeadNextEvent `$C53B` |
| | `music/menu/lead-riff.bin` | `$C789-$C7A9` | 33 | `LeadRiff` | the same (call) |
| | `music/menu/lead-phrase.bin` | `$C7AA-$C7C4` | 27 | `LeadPhrase` | the same (call) |
| | `music/menu/lead-arpeggio-a.bin` | `$C7C5-$C7D1` | 13 | `LeadArpeggioA` | the same (call) |
| | `music/menu/lead-arpeggio-b.bin` | `$C7D2-$C7DE` | 13 | `LeadArpeggioB` | the same (call) |
| | `music/menu/lead-scale.bin` | `$C7DF-$C81F` | 65 | `LeadScale` | the same (call) |

### The sprites

Each file holds a header entry (`SprX`, 2 bytes) and its rows entry (`SprXRows`). Id = the sprite id the code
draws (SpriteTable index in brackets: 2 x id + the half-byte column parity). Names from ../nether-earth/work/ann/d1.md.

| Source | Address | Bytes | Entries | Lines x bytes | Id (index) | What |
| --- | --- | ---: | --- | --- | --- | --- |
| `gfx/sprites/tracks-x.png` | `$6980-$6A23` | 164 | `SprTracksX`, `SprTracksXRows` | 27 x 3 | 22 (44) | tracks, moving along X (directions 0-1) |
| `gfx/sprites/tracks-x-odd.png` | `$6A24-$6AFD` | 218 | `SprTracksXOdd`, `SprTracksXOddRows` | 27 x 4 | 22 (45) | tracks, moving along X (directions 0-1) |
| `gfx/sprites/tracks-y.png` | `$6AFE-$6BA7` | 170 | `SprTracksY`, `SprTracksYRows` | 28 x 3 | 23 (46) | tracks, moving along Y (directions 2-3) |
| `gfx/sprites/tracks-y-odd.png` | `$6BA8-$6C89` | 226 | `SprTracksYOdd`, `SprTracksYOddRows` | 28 x 4 | 23 (47) | tracks, moving along Y (directions 2-3) |
| `gfx/sprites/bipod-x.png` | `$6C8A-$6D3F` | 182 | `SprBipodX`, `SprBipodXRows` | 30 x 3 | 24 (48) | bipod legs, along X |
| `gfx/sprites/bipod-x-odd.png` | `$6D40-$6E31` | 242 | `SprBipodXOdd`, `SprBipodXOddRows` | 30 x 4 | 24 (49) | bipod legs, along X |
| `gfx/sprites/bipod-y.png` | `$6E32-$6EE1` | 176 | `SprBipodY`, `SprBipodYRows` | 29 x 3 | 25 (50) | bipod legs, along Y |
| `gfx/sprites/bipod-y-odd.png` | `$6EE2-$6FCB` | 234 | `SprBipodYOdd`, `SprBipodYOddRows` | 29 x 4 | 25 (51) | bipod legs, along Y |
| `gfx/sprites/anti-grav.png` | `$6FCC-$7057` | 140 | `SprAntiGrav`, `SprAntiGravRows` | 23 x 3 | 26 (52) | anti-grav unit, every direction |
| `gfx/sprites/anti-grav-odd.png` | `$7058-$7111` | 186 | `SprAntiGravOdd`, `SprAntiGravOddRows` | 23 x 4 | 26 (53) | anti-grav unit, every direction |
| `gfx/sprites/cannon-xp.png` | `$7112-$71BB` | 170 | `SprCannonXp`, `SprCannonXpRows` | 28 x 3 | 27 (54) | cannon facing X+ (direction 0) |
| `gfx/sprites/cannon-xp-odd.png` | `$71BC-$729D` | 226 | `SprCannonXpOdd`, `SprCannonXpOddRows` | 28 x 4 | 27 (55) | cannon facing X+ (direction 0) |
| `gfx/sprites/cannon-xm.png` | `$729E-$7353` | 182 | `SprCannonXm`, `SprCannonXmRows` | 30 x 3 | 28 (56) | cannon facing X- (direction 1) |
| `gfx/sprites/cannon-xm-odd.png` | `$7354-$7445` | 242 | `SprCannonXmOdd`, `SprCannonXmOddRows` | 30 x 4 | 28 (57) | cannon facing X- (direction 1) |
| `gfx/sprites/cannon-yp.png` | `$7446-$74FB` | 182 | `SprCannonYp`, `SprCannonYpRows` | 30 x 3 | 29 (58) | cannon facing Y+ (direction 2) |
| `gfx/sprites/cannon-yp-odd.png` | `$74FC-$75ED` | 242 | `SprCannonYpOdd`, `SprCannonYpOddRows` | 30 x 4 | 29 (59) | cannon facing Y+ (direction 2) |
| `gfx/sprites/cannon-ym.png` | `$75EE-$7685` | 152 | `SprCannonYm`, `SprCannonYmRows` | 25 x 3 | 30 (60) | cannon facing Y- (direction 3) |
| `gfx/sprites/cannon-ym-odd.png` | `$7686-$774F` | 202 | `SprCannonYmOdd`, `SprCannonYmOddRows` | 25 x 4 | 30 (61) | cannon facing Y- (direction 3) |
| `gfx/sprites/missiles-x.png` | `$7750-$77F3` | 164 | `SprMissilesX`, `SprMissilesXRows` | 27 x 3 | 31 (62) | missile pod along X |
| `gfx/sprites/missiles-x-odd.png` | `$77F4-$78CD` | 218 | `SprMissilesXOdd`, `SprMissilesXOddRows` | 27 x 4 | 31 (63) | missile pod along X |
| `gfx/sprites/missiles-y.png` | `$78CE-$7977` | 170 | `SprMissilesY`, `SprMissilesYRows` | 28 x 3 | 32 (64) | missile pod along Y |
| `gfx/sprites/missiles-y-odd.png` | `$7978-$7A59` | 226 | `SprMissilesYOdd`, `SprMissilesYOddRows` | 28 x 4 | 32 (65) | missile pod along Y |
| `gfx/sprites/phasers-xp.png` | `$7A5A-$7B03` | 170 | `SprPhasersXp`, `SprPhasersXpRows` | 28 x 3 | 33 (66) | phasers facing X+ |
| `gfx/sprites/phasers-xp-odd.png` | `$7B04-$7BE5` | 226 | `SprPhasersXpOdd`, `SprPhasersXpOddRows` | 28 x 4 | 33 (67) | phasers facing X+ |
| `gfx/sprites/phasers-xm.png` | `$7BE6-$7C95` | 176 | `SprPhasersXm`, `SprPhasersXmRows` | 29 x 3 | 34 (68) | phasers facing X- |
| `gfx/sprites/phasers-xm-odd.png` | `$7C96-$7D7F` | 234 | `SprPhasersXmOdd`, `SprPhasersXmOddRows` | 29 x 4 | 34 (69) | phasers facing X- |
| `gfx/sprites/phasers-yp.png` | `$7D80-$7E2F` | 176 | `SprPhasersYp`, `SprPhasersYpRows` | 29 x 3 | 35 (70) | phasers facing Y+ |
| `gfx/sprites/phasers-yp-odd.png` | `$7E30-$7F19` | 234 | `SprPhasersYpOdd`, `SprPhasersYpOddRows` | 29 x 4 | 35 (71) | phasers facing Y+ |
| `gfx/sprites/phasers-ym.png` | `$7F1A-$7FB7` | 158 | `SprPhasersYm`, `SprPhasersYmRows` | 26 x 3 | 36 (72) | phasers facing Y- |
| `gfx/sprites/phasers-ym-odd.png` | `$7FB8-$8089` | 210 | `SprPhasersYmOdd`, `SprPhasersYmOddRows` | 26 x 4 | 36 (73) | phasers facing Y- |
| `gfx/sprites/nuclear.png` | `$808A-$8139` | 176 | `SprNuclear`, `SprNuclearRows` | 29 x 3 | 37 (74) | nuclear bomb (the ball with the trefoil), every direction |
| `gfx/sprites/nuclear-odd.png` | `$813A-$8223` | 234 | `SprNuclearOdd`, `SprNuclearOddRows` | 29 x 4 | 37 (75) | nuclear bomb (the ball with the trefoil), every direction |
| `gfx/sprites/electronics-xp.png` | `$8224-$82B5` | 146 | `SprElectronicsXp`, `SprElectronicsXpRows` | 24 x 3 | 38 (76) | electronics dome facing X+ |
| `gfx/sprites/electronics-xp-odd.png` | `$82B6-$8347` | 146 | `SprElectronicsXpOdd`, `SprElectronicsXpOddRows` | 24 x 3 | 38 (77) | electronics dome facing X+ |
| `gfx/sprites/electronics-xm.png` | `$8348-$83D9` | 146 | `SprElectronicsXm`, `SprElectronicsXmRows` | 24 x 3 | 39 (78) | electronics dome facing X- |
| `gfx/sprites/electronics-xm-odd.png` | `$83DA-$846B` | 146 | `SprElectronicsXmOdd`, `SprElectronicsXmOddRows` | 24 x 3 | 39 (79) | electronics dome facing X- |
| `gfx/sprites/electronics-yp.png` | `$846C-$84FD` | 146 | `SprElectronicsYp`, `SprElectronicsYpRows` | 24 x 3 | 40 (80) | electronics dome facing Y+ |
| `gfx/sprites/electronics-yp-odd.png` | `$84FE-$858F` | 146 | `SprElectronicsYpOdd`, `SprElectronicsYpOddRows` | 24 x 3 | 40 (81) | electronics dome facing Y+ |
| `gfx/sprites/electronics-ym.png` | `$8590-$8621` | 146 | `SprElectronicsYm`, `SprElectronicsYmRows` | 24 x 3 | 41 (82) | electronics dome facing Y- |
| `gfx/sprites/electronics-ym-odd.png` | `$8622-$86B3` | 146 | `SprElectronicsYmOdd`, `SprElectronicsYmOddRows` | 24 x 3 | 41 (83) | electronics dome facing Y- |
| `gfx/sprites/flag-player.png` | `$86B4-$86F7` | 68 | `SprFlagPlayer`, `SprFlagPlayerRows` | 11 x 3 | 42 (84) | the player's flag, building type 7 |
| `gfx/sprites/flag-player-odd.png` | `$86F8-$8751` | 90 | `SprFlagPlayerOdd`, `SprFlagPlayerOddRows` | 11 x 4 | 42 (85) | the player's flag, building type 7 |
| `gfx/sprites/flag-enemy.png` | `$8752-$8795` | 68 | `SprFlagEnemy`, `SprFlagEnemyRows` | 11 x 3 | 43 (86) | the enemy's flag, building type 8 |
| `gfx/sprites/flag-enemy-odd.png` | `$8796-$87EF` | 90 | `SprFlagEnemyOdd`, `SprFlagEnemyOddRows` | 11 x 4 | 43 (87) | the enemy's flag, building type 8 |
| `gfx/sprites/warbase-sign.png` | `$87F0-$8857` | 104 | `SprWarbaseSign`, `SprWarbaseSignRows` | 17 x 3 | 44 (88) | the warbase sign, building type 0 |
| `gfx/sprites/warbase-sign-odd.png` | `$8858-$88E1` | 138 | `SprWarbaseSignOdd`, `SprWarbaseSignOddRows` | 17 x 4 | 44 (89) | the warbase sign, building type 0 |
| `gfx/sprites/shot-cannon-x.png` | `$88E2-$8923` | 66 | `SprShotCannonX`, `SprShotCannonXRows` | 16 x 2 | 45 (90) | cannon shell, flying along X |
| `gfx/sprites/shot-cannon-x-odd.png` | `$8924-$8965` | 66 | `SprShotCannonXOdd`, `SprShotCannonXOddRows` | 16 x 2 | 45 (91) | cannon shell, flying along X |
| `gfx/sprites/shot-cannon-y.png` | `$8966-$89B5` | 80 | `SprShotCannonY`, `SprShotCannonYRows` | 13 x 3 | 46 (92) | cannon shell, flying along Y |
| `gfx/sprites/shot-cannon-y-odd.png` | `$89B6-$8A05` | 80 | `SprShotCannonYOdd`, `SprShotCannonYOddRows` | 13 x 3 | 46 (93) | cannon shell, flying along Y |
| `gfx/sprites/shot-missile-x.png` | `$8A06-$8A8B` | 134 | `SprShotMissileX`, `SprShotMissileXRows` | 22 x 3 | 47 (94) | missile, flying along X |
| `gfx/sprites/shot-missile-x-odd.png` | `$8A8C-$8B3D` | 178 | `SprShotMissileXOdd`, `SprShotMissileXOddRows` | 22 x 4 | 47 (95) | missile, flying along X |
| `gfx/sprites/shot-missile-y.png` | `$8B3E-$8BC3` | 134 | `SprShotMissileY`, `SprShotMissileYRows` | 22 x 3 | 48 (96) | missile, flying along Y |
| `gfx/sprites/shot-missile-y-odd.png` | `$8BC4-$8C75` | 178 | `SprShotMissileYOdd`, `SprShotMissileYOddRows` | 22 x 4 | 48 (97) | missile, flying along Y |
| `gfx/sprites/shot-phaser-x.png` | `$8C76-$8CDD` | 104 | `SprShotPhaserX`, `SprShotPhaserXRows` | 17 x 3 | 49 (98) | phaser beam, along X |
| `gfx/sprites/shot-phaser-x-odd.png` | `$8CDE-$8D45` | 104 | `SprShotPhaserXOdd`, `SprShotPhaserXOddRows` | 17 x 3 | 49 (99) | phaser beam, along X |
| `gfx/sprites/shot-phaser-y.png` | `$8D46-$8DBF` | 122 | `SprShotPhaserY`, `SprShotPhaserYRows` | 20 x 3 | 50 (100) | phaser beam, along Y |
| `gfx/sprites/shot-phaser-y-odd.png` | `$8DC0-$8E39` | 122 | `SprShotPhaserYOdd`, `SprShotPhaserYOddRows` | 20 x 3 | 50 (101) | phaser beam, along Y |
| `gfx/sprites/ship.png` | `$8E3A-$8F2B` | 242 | `SprShip`, `SprShipRows` | 30 x 4 | 0 (0), 19 (38), 19 (39), 20 (40), 20 (41) | the player's ship |
| `gfx/sprites/ship-odd.png` | `$8F2C-$901D` | 242 | `SprShipOdd`, `SprShipOddRows` | 30 x 4 | 0 (1) | the player's ship |
| `gfx/sprites/shadow.png` | `$901E-$90AF` | 146 | `SprShadow`, `SprShadowRows` | 24 x 3 | 1 (2) | the ship's shadow on the ground |
| `gfx/sprites/shadow-odd.png` | `$90B0-$9171` | 194 | `SprShadowOdd`, `SprShadowOddRows` | 24 x 4 | 1 (3) | the ship's shadow on the ground |
| `gfx/sprites/stones-a.png` | `$9172-$91F1` | 128 | `SprStonesA`, `SprStonesARows` | 21 x 3 | 2 (4), 2 (5) | stones, map type 2 |
| `gfx/sprites/stones-b.png` | `$91F2-$9277` | 134 | `SprStonesB`, `SprStonesBRows` | 22 x 3 | 3 (6), 3 (7) | stones, map type 3 |
| `gfx/sprites/stones-c.png` | `$9278-$92F7` | 128 | `SprStonesC`, `SprStonesCRows` | 21 x 3 | 4 (8), 4 (9) | stones, map type 4 |
| `gfx/sprites/stones-d.png` | `$92F8-$9371` | 122 | `SprStonesD`, `SprStonesDRows` | 20 x 3 | 5 (10), 5 (11) | stones, map type 5 |
| `gfx/sprites/rocks-a.png` | `$9372-$9409` | 152 | `SprRocksA`, `SprRocksARows` | 25 x 3 | 8 (16), 8 (17) | rocks, map type 8 |
| `gfx/sprites/rocks-b.png` | `$940A-$94A7` | 158 | `SprRocksB`, `SprRocksBRows` | 26 x 3 | 9 (18), 9 (19) | rocks, map type 9 |
| `gfx/sprites/rocks-c.png` | `$94A8-$9533` | 140 | `SprRocksC`, `SprRocksCRows` | 23 x 3 | 10 (20), 10 (21) | rocks, map type 10 |
| `gfx/sprites/rocks-d.png` | `$9534-$95C5` | 146 | `SprRocksD`, `SprRocksDRows` | 24 x 3 | 11 (22), 11 (23) | rocks, map type 11 |
| `gfx/sprites/trench-start-y.png` | `$95C6-$963F` | 122 | `SprTrenchStartY`, `SprTrenchStartYRows` | 20 x 3 | 12 (24) | trench start along Y (map type 12 on even rows) |
| `gfx/sprites/trench-start-x.png` | `$9640-$96E9` | 170 | `SprTrenchStartX`, `SprTrenchStartXRows` | 21 x 4 | 12 (25) | trench start along X (map type 12 on odd rows) |
| `gfx/sprites/trench-middle-y.png` | `$96EA-$9775` | 140 | `SprTrenchMiddleY`, `SprTrenchMiddleYRows` | 23 x 3 | 13 (26) | trench middle along Y (map type 13 on even rows) |
| `gfx/sprites/trench-middle-x.png` | `$9776-$981F` | 170 | `SprTrenchMiddleX`, `SprTrenchMiddleXRows` | 21 x 4 | 13 (27) | trench middle along X (map type 13 on odd rows) |
| `gfx/sprites/trench-end-y.png` | `$9820-$98AB` | 140 | `SprTrenchEndY`, `SprTrenchEndYRows` | 23 x 3 | 14 (28) | trench end along Y (map type 14 on even rows) |
| `gfx/sprites/trench-end-x.png` | `$98AC-$9913` | 104 | `SprTrenchEndX`, `SprTrenchEndXRows` | 17 x 3 | 14 (29) | trench end along X (map type 14 on odd rows) |
| `gfx/sprites/block-low.png` | `$9914-$9A15` | 258 | `SprBlockLow`, `SprBlockLowRows` | 32 x 4 | 15 (30) | low block, map type 15 |
| `gfx/sprites/block-low-odd.png` | `$9A16-$9B17` | 258 | `SprBlockLowOdd`, `SprBlockLowOddRows` | 32 x 4 | 15 (31) | low block, map type 15 |
| `gfx/sprites/block-tall.png` | `$9B18-$9C59` | 322 | `SprBlockTall`, `SprBlockTallRows` | 40 x 4 | 16 (32) | tall block with an arch, map type 16 |
| `gfx/sprites/block-tall-odd.png` | `$9C5A-$9D9B` | 322 | `SprBlockTallOdd`, `SprBlockTallOddRows` | 40 x 4 | 16 (33) | tall block with an arch, map type 16 |
| `gfx/sprites/boulders-a.png` | `$9D9C-$9E33` | 152 | `SprBouldersA`, `SprBouldersARows` | 25 x 3 | 6 (12) | boulders, map type 6 |
| `gfx/sprites/boulders-a-odd.png` | `$9E34-$9EF5` | 194 | `SprBouldersAOdd`, `SprBouldersAOddRows` | 24 x 4 | 6 (13) | boulders, map type 6 |
| `gfx/sprites/boulders-b.png` | `$9EF6-$9F8D` | 152 | `SprBouldersB`, `SprBouldersBRows` | 25 x 3 | 7 (14) | boulders, map type 7 |
| `gfx/sprites/boulders-b-odd.png` | `$9F8E-$A04F` | 194 | `SprBouldersBOdd`, `SprBouldersBOddRows` | 24 x 4 | 7 (15) | boulders, map type 7 |
| `gfx/sprites/post.png` | `$A050-$A0E1` | 146 | `SprPost`, `SprPostRows` | 36 x 2 | 21 (42), 21 (43) | border post, map type 21 |
| `gfx/sprites/block-door.png` | `$A0E2-$A1E3` | 258 | `SprBlockDoor`, `SprBlockDoorRows` | 32 x 4 | 17 (34) | low block with a door, map type 17 on even rows |
| `gfx/sprites/block-window.png` | `$A1E4-$A2E5` | 258 | `SprBlockWindow`, `SprBlockWindowRows` | 32 x 4 | 17 (35) | low block with a window, map type 17 on odd rows |
| `gfx/sprites/block-grid.png` | `$A2E6-$A427` | 322 | `SprBlockGrid`, `SprBlockGridRows` | 40 x 4 | 18 (36) | tall block with a grid face and a door, map type 18 on even rows |
| `gfx/sprites/block-dotted.png` | `$A428-$A569` | 322 (the `.bin` 321) | `SprBlockDotted`, `SprBlockDottedRows` | 40 x 4 | 18 (37) | tall block with a dotted face, map type 18 on odd rows; its last byte `$A569` is `GsMenuSound`'s `DI` |
