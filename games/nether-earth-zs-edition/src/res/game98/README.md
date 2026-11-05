# The '98 game's resources

The data of the '98 game (`NEZSEd.B` sectors 44-156, `$6780-$D87F`) that is not code: the font, the 89 sprite
blocks, the view's edge patterns, the order names, the level (ZS's own scenery and base lists, NE's shape table and
shapes) and the menu tune. Each is kept in an editable source here; `tools/game98_res.py` (a copy of Nether Earth's
`tools/res_formats.py` with this part's paths) turns the sources into the original `.bin` files under
`build/game98/res/game98`, and `tools/build_game98.sh` (which runs it first) assembles `src/game98/game98.asm` with
`INCBIN "res/game98/..."` from there and compares the result with the file's 28928 bytes.

- **Where they come from.** An entry of `src/game98/game.ann` followed by `@res game98/FILE` is a resource:
  `tools/game98_mkgame.py` (kit/mkgame.py with this part's config) writes its bytes, and its data lines in
  `src/game98/*.asm` become `INCBIN` lines under the entry's label. Entries that name one file share it: a sprite's
  header and rows, the two view edges, the nine order names. `tools/game98_mkgame.py --install` writes them through
  `game98_res.install`: every file here is an editable source, no `.bin` is kept. Edit the sources, not the `.asm`.
- **What differs from NE.** Four sprite blocks (the table below), the scenery and base lists (`map/level.txt`).
  The font, the edges, the order names, the shapes and the tune are NE's bytes.
- **Checked against the recordings.** No byte of any file here is written in this part's `play` or `deep` L1
  windows (`byte_counts` writes: none for all 121 files), and memory at the start of `deep`
  (`work/stage2/game98/deep/start.bin`) holds every file's bytes at its address. The `key5menu` window writes into
  112 of them: that is the broken LOAD NEW LEVEL's map build running over the whole 64 K (`src/game98/game.ann`,
  LoadNewLevel).
- **Commands.**

```sh
python3 tools/game98_res.py build --out build/game98/res   # the sources -> res/game98/*.bin, what the source INCBINs
python3 tools/game98_res.py check                          # each source built, written back out, built again: same bytes
python3 tools/game98_res.py export --from DIR              # .bin files -> sources here
sh tools/build_game98.sh                                   # the resources, the assembly, the byte-for-byte check
```

The same two fixed bases as in NE hold: `ShowOrder` finds a name at `OrderNames - 27 + 27 x (order + 1)`, and the
font stays at `$6780` (`PrintChar` / `PrintBigChar` use `Font - $100 + 8 x code`).

## Formats

The formats are NE's (Nether Earth's `src/res/README.md`, Formats), with one addition in the level text.

| Format | Layout |
| --- | --- |
| **Font PNG** (`gfx/font.png`) | 128 x 32: 64 glyphs of 8 x 8, 16 a row, in code order from `$20`. Palette: 0 paper, 1 ink. The `.bin` is 8 bytes a glyph, one byte a pixel line from the top, bit 7 the leftmost pixel. |
| **Sprite PNG** (`gfx/sprites/*.png`) | One block, upright, as wide as its bytes x 8 and as tall as its lines. The `.bin`: byte 0 the lines, byte 1 the width in bytes, then the rows from the BOTTOM line up, each `width` pairs (mask, graphic); a pixel is `(screen AND mask) OR graphic` (DrawSprite `$CF2D`, DrawMaskedUp `$D315`). Palette: 0 see-through (mask 1, graphic 0), 1 paper (mask 0, graphic 0), 2 ink (mask 0, graphic 1), 3 ink over the background (mask 1, graphic 1). The '98 has six bytes with such pixels: NE's three (`$71A6` in cannon-xp, `$7282` in cannon-xp-odd, `$7676` in cannon-ym) and three ZS made when redrawing (`$767E` mask `$1F` graphic `$04` in cannon-ym, `$837E` `$7F`/`$1F` in electronics-xm, `$985C` `$AF`/`$4E` in trench-end-y). |
| **View edges PNG** (`gfx/view-edges.png`) | 32 x 8: ViewEdgeA (left 16 pixels) and ViewEdgeB (right 16). Palette 0 paper, 1 ink. The `.bin`: per pattern 8 lines of 2 bytes, top line first, left byte first. |
| **Level text** (`map/level.txt`) | The sections `scenery SceneryWest`, `scenery SceneryEast`, `bases BaseListWest`, `bases BaseListEast`, `table ShapeTable`, then `shape ShapeWarbase` ... `shape ShapeMixedWallH` (11), in this order from `$BDA9`. Scenery: `block TILE x y` (a 2 x 2 block, PutBlock), `shape N x y` (record `$80+N`, DrawShape), `end` (0). Bases: `warbase x y`, `factory T x y` (T 1-6: electronics, nuclear, phasers, missiles, cannon, chassis), `end` (`$FF`). A column x is 0-511: the West lists hold 0-255, the East lists 256-511. Table: `dw Label`. Shape: `block TILE move DX DY`, `move DX DY`, `block TILE end` / `end`. `db` / `dw` write bytes as they are. New here: bytes after a scenery list's `end` are written as `db ...  ; after the end: never read` (SceneryWest's 9 zero bytes `$BE70-$BE78`, which keep SceneryEast at NE's address). |
| **Menu tune text** (`music/menu.txt`) | NE's sections and commands, from `$C665`: drums `hiss N`, `rasp N [K]`, `sweep N P`, `goto Label`; voices `note P N`, `goto`, `call`, `drums`, `on`, `off`, `return`. |
| **Order names text** (`text/order-names.txt`) | `N "line 1" "line 2" "line 3"`, orders 0-8, each line 8 characters; 27 bytes an order (lines joined by code 3, ended by 0). |

## Files

Addresses are where the bytes sit in the '98 game (`$6780-$D87F`). The entries are the labels of
`src/game98/game.ann` that carry `@res`.

| Source | Builds | Address | Bytes | Entries | Read by |
| --- | --- | --- | ---: | --- | --- |
| `gfx/font.png` | `gfx/font.bin` | `$6780-$697F` | 512 | `Font` | PrintChar `$D4B1`, PrintBigChar `$D4DA` |
| `gfx/sprites/*.png` (89) | `gfx/sprites/*.bin` | `$6980-$A569` | 15 338 | `Spr*`, `Spr*Rows` (table below) | DrawSprite `$CF2D` through SpriteTable `$D6E8`; the construction menu's part icons through DrawMaskedUp `$D315` |
| `gfx/view-edges.png` | `gfx/view-edges.bin` | `$D6A8-$D6C7` | 32 | `ViewEdgeA`, `ViewEdgeB` | DrawViewBackground `$CFD7`, DrawEdgeStrips `$D057` |
| `text/order-names.txt` | `text/order-names.bin` | `$A848-$A93A` | 243 | `OrderNames`, `OrderName1`-`OrderName8` | ShowOrder `$A795` |
| `map/level.txt` | `map/scenery-west.bin` | `$BDA9-$BE78` | 208 | `SceneryWest` | BuildMap `$BC6F` / PlaceScenery `$BCD6`, D = 0: 66 records, the end, 9 zero bytes (ZS) |
| | `map/scenery-east.bin` | `$BE79-$BF45` | 205 | `SceneryEast` | the same, D = 1: 68 records (ZS) |
| | `map/bases-west.bin` | `$BF46-$BF6D` | 40 | `BaseListWest` | PlaceBases `$BCF9`: the player's warbase (22,14) and 12 factories (ZS) |
| | `map/bases-east.bin` | `$BF6E-$BF9B` | 46 | `BaseListEast` | PlaceBases: the enemy's 3 warbases and 12 factories (ZS) |
| | `map/shape-table.bin` | `$BF9C-$BFB1` | 22 | `ShapeTable` | DrawShape `$BD61` (11 words) |
| | `map/shapes/warbase.bin` | `$BFB2-$BFE1` | 48 | `ShapeWarbase` | shape 0 |
| | `map/shapes/factory.bin` | `$BFE2-$BFF3` | 18 | `ShapeFactory` | shape 1 |
| | `map/shapes/low-tiles.bin` | `$BFF4-$C017` | 36 | `ShapeLowTiles` | shape 2 |
| | `map/shapes/mid-tiles.bin` | `$C018-$C03B` | 36 | `ShapeMidTiles` | shape 3 |
| | `map/shapes/tall-wall-v.bin` | `$C03C-$C047` | 12 | `ShapeTallWallV` | shape 4 |
| | `map/shapes/tall-wall-h.bin` | `$C048-$C053` | 12 | `ShapeTallWallH` | shape 5 |
| | `map/shapes/edge-fence.bin` | `$C054-$C05F` | 12 | `ShapeEdgeFence` | shape 6 |
| | `map/shapes/flat-line-v.bin` | `$C060-$C06B` | 12 | `ShapeFlatLineV` | shape 7 |
| | `map/shapes/flat-line-h.bin` | `$C06C-$C077` | 12 | `ShapeFlatLineH` | shape 8 |
| | `map/shapes/low-wall-h.bin` | `$C078-$C083` | 12 | `ShapeLowWallH` | shape 9 |
| | `map/shapes/mixed-wall-h.bin` | `$C084-$C08C` | 9 | `ShapeMixedWallH` | shape 10 |
| `music/menu.txt` | `music/menu/drum-steady.bin` | `$C665-$C669` | 5 | `DrumTrackSteady` | DrumStep `$C5DB` |
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
draws (SpriteTable index in brackets: 2 x id + the half-byte column parity). Origin: NE = NE's bytes; ZS = changed.

| Source | Address | Bytes | Entries | Lines x bytes | Id (index) | What | Origin |
| --- | --- | ---: | --- | --- | --- | --- | --- |
| `gfx/sprites/tracks-x.png` | `$6980-$6A23` | 164 | `SprTracksX`, `SprTracksXRows` | 27 x 3 | 22 (44) | tracks, moving along X (directions 0-1) | NE |
| `gfx/sprites/tracks-x-odd.png` | `$6A24-$6AFD` | 218 | `SprTracksXOdd`, `SprTracksXOddRows` | 27 x 4 | 22 (45) | tracks, moving along X (directions 0-1) | NE |
| `gfx/sprites/tracks-y.png` | `$6AFE-$6BA7` | 170 | `SprTracksY`, `SprTracksYRows` | 28 x 3 | 23 (46) | tracks, moving along Y (directions 2-3) | NE |
| `gfx/sprites/tracks-y-odd.png` | `$6BA8-$6C89` | 226 | `SprTracksYOdd`, `SprTracksYOddRows` | 28 x 4 | 23 (47) | tracks, moving along Y (directions 2-3) | NE |
| `gfx/sprites/bipod-x.png` | `$6C8A-$6D3F` | 182 | `SprBipodX`, `SprBipodXRows` | 30 x 3 | 24 (48) | bipod legs, along X | NE |
| `gfx/sprites/bipod-x-odd.png` | `$6D40-$6E31` | 242 | `SprBipodXOdd`, `SprBipodXOddRows` | 30 x 4 | 24 (49) | bipod legs, along X | NE |
| `gfx/sprites/bipod-y.png` | `$6E32-$6EE1` | 176 | `SprBipodY`, `SprBipodYRows` | 29 x 3 | 25 (50) | bipod legs, along Y | NE |
| `gfx/sprites/bipod-y-odd.png` | `$6EE2-$6FCB` | 234 | `SprBipodYOdd`, `SprBipodYOddRows` | 29 x 4 | 25 (51) | bipod legs, along Y | NE |
| `gfx/sprites/anti-grav.png` | `$6FCC-$7057` | 140 | `SprAntiGrav`, `SprAntiGravRows` | 23 x 3 | 26 (52) | anti-grav unit, every direction | NE |
| `gfx/sprites/anti-grav-odd.png` | `$7058-$7111` | 186 | `SprAntiGravOdd`, `SprAntiGravOddRows` | 23 x 4 | 26 (53) | anti-grav unit, every direction | NE |
| `gfx/sprites/cannon-xp.png` | `$7112-$71BB` | 170 | `SprCannonXp`, `SprCannonXpRows` | 28 x 3 | 27 (54) | cannon facing X+ (direction 0) | NE |
| `gfx/sprites/cannon-xp-odd.png` | `$71BC-$729D` | 226 | `SprCannonXpOdd`, `SprCannonXpOddRows` | 28 x 4 | 27 (55) | cannon facing X+ (direction 0) | NE |
| `gfx/sprites/cannon-xm.png` | `$729E-$7353` | 182 | `SprCannonXm`, `SprCannonXmRows` | 30 x 3 | 28 (56) | cannon facing X- (direction 1) | NE |
| `gfx/sprites/cannon-xm-odd.png` | `$7354-$7445` | 242 | `SprCannonXmOdd`, `SprCannonXmOddRows` | 30 x 4 | 28 (57) | cannon facing X- (direction 1) | NE |
| `gfx/sprites/cannon-yp.png` | `$7446-$74FB` | 182 | `SprCannonYp`, `SprCannonYpRows` | 30 x 3 | 29 (58) | cannon facing Y+ (direction 2) | NE |
| `gfx/sprites/cannon-yp-odd.png` | `$74FC-$75ED` | 242 | `SprCannonYpOdd`, `SprCannonYpOddRows` | 30 x 4 | 29 (59) | cannon facing Y+ (direction 2) | NE |
| `gfx/sprites/cannon-ym.png` | `$75EE-$7685` | 152 | `SprCannonYm`, `SprCannonYmRows` | 25 x 3 | 30 (60) | cannon facing Y- (direction 3) | ZS: 1 byte (`$767F`) |
| `gfx/sprites/cannon-ym-odd.png` | `$7686-$774F` | 202 | `SprCannonYmOdd`, `SprCannonYmOddRows` | 25 x 4 | 30 (61) | cannon facing Y- (direction 3) | NE |
| `gfx/sprites/missiles-x.png` | `$7750-$77F3` | 164 | `SprMissilesX`, `SprMissilesXRows` | 27 x 3 | 31 (62) | missile pod along X | NE |
| `gfx/sprites/missiles-x-odd.png` | `$77F4-$78CD` | 218 | `SprMissilesXOdd`, `SprMissilesXOddRows` | 27 x 4 | 31 (63) | missile pod along X | NE |
| `gfx/sprites/missiles-y.png` | `$78CE-$7977` | 170 | `SprMissilesY`, `SprMissilesYRows` | 28 x 3 | 32 (64) | missile pod along Y | NE |
| `gfx/sprites/missiles-y-odd.png` | `$7978-$7A59` | 226 | `SprMissilesYOdd`, `SprMissilesYOddRows` | 28 x 4 | 32 (65) | missile pod along Y | NE |
| `gfx/sprites/phasers-xp.png` | `$7A5A-$7B03` | 170 | `SprPhasersXp`, `SprPhasersXpRows` | 28 x 3 | 33 (66) | phasers facing X+ | NE |
| `gfx/sprites/phasers-xp-odd.png` | `$7B04-$7BE5` | 226 | `SprPhasersXpOdd`, `SprPhasersXpOddRows` | 28 x 4 | 33 (67) | phasers facing X+ | NE |
| `gfx/sprites/phasers-xm.png` | `$7BE6-$7C95` | 176 | `SprPhasersXm`, `SprPhasersXmRows` | 29 x 3 | 34 (68) | phasers facing X- | NE |
| `gfx/sprites/phasers-xm-odd.png` | `$7C96-$7D7F` | 234 | `SprPhasersXmOdd`, `SprPhasersXmOddRows` | 29 x 4 | 34 (69) | phasers facing X- | NE |
| `gfx/sprites/phasers-yp.png` | `$7D80-$7E2F` | 176 | `SprPhasersYp`, `SprPhasersYpRows` | 29 x 3 | 35 (70) | phasers facing Y+ | NE |
| `gfx/sprites/phasers-yp-odd.png` | `$7E30-$7F19` | 234 | `SprPhasersYpOdd`, `SprPhasersYpOddRows` | 29 x 4 | 35 (71) | phasers facing Y+ | NE |
| `gfx/sprites/phasers-ym.png` | `$7F1A-$7FB7` | 158 | `SprPhasersYm`, `SprPhasersYmRows` | 26 x 3 | 36 (72) | phasers facing Y- | NE |
| `gfx/sprites/phasers-ym-odd.png` | `$7FB8-$8089` | 210 | `SprPhasersYmOdd`, `SprPhasersYmOddRows` | 26 x 4 | 36 (73) | phasers facing Y- | NE |
| `gfx/sprites/nuclear.png` | `$808A-$8139` | 176 | `SprNuclear`, `SprNuclearRows` | 29 x 3 | 37 (74) | nuclear bomb (the ball with the trefoil), every direction | NE |
| `gfx/sprites/nuclear-odd.png` | `$813A-$8223` | 234 | `SprNuclearOdd`, `SprNuclearOddRows` | 29 x 4 | 37 (75) | nuclear bomb (the ball with the trefoil), every direction | NE |
| `gfx/sprites/electronics-xp.png` | `$8224-$82B5` | 146 | `SprElectronicsXp`, `SprElectronicsXpRows` | 24 x 3 | 38 (76) | electronics dome facing X+ | NE |
| `gfx/sprites/electronics-xp-odd.png` | `$82B6-$8347` | 146 | `SprElectronicsXpOdd`, `SprElectronicsXpOddRows` | 24 x 3 | 38 (77) | electronics dome facing X+ | NE |
| `gfx/sprites/electronics-xm.png` | `$8348-$83D9` | 146 | `SprElectronicsXm`, `SprElectronicsXmRows` | 24 x 3 | 39 (78) | electronics dome facing X- | ZS: 2 bytes (`$837F`, `$8383`) |
| `gfx/sprites/electronics-xm-odd.png` | `$83DA-$846B` | 146 | `SprElectronicsXmOdd`, `SprElectronicsXmOddRows` | 24 x 3 | 39 (79) | electronics dome facing X- | NE |
| `gfx/sprites/electronics-yp.png` | `$846C-$84FD` | 146 | `SprElectronicsYp`, `SprElectronicsYpRows` | 24 x 3 | 40 (80) | electronics dome facing Y+ | NE |
| `gfx/sprites/electronics-yp-odd.png` | `$84FE-$858F` | 146 | `SprElectronicsYpOdd`, `SprElectronicsYpOddRows` | 24 x 3 | 40 (81) | electronics dome facing Y+ | NE |
| `gfx/sprites/electronics-ym.png` | `$8590-$8621` | 146 | `SprElectronicsYm`, `SprElectronicsYmRows` | 24 x 3 | 41 (82) | electronics dome facing Y- | NE |
| `gfx/sprites/electronics-ym-odd.png` | `$8622-$86B3` | 146 | `SprElectronicsYmOdd`, `SprElectronicsYmOddRows` | 24 x 3 | 41 (83) | electronics dome facing Y- | NE |
| `gfx/sprites/flag-player.png` | `$86B4-$86F7` | 68 | `SprFlagPlayer`, `SprFlagPlayerRows` | 11 x 3 | 42 (84) | the player's flag, building type 7 | NE |
| `gfx/sprites/flag-player-odd.png` | `$86F8-$8751` | 90 | `SprFlagPlayerOdd`, `SprFlagPlayerOddRows` | 11 x 4 | 42 (85) | the player's flag, building type 7 | NE |
| `gfx/sprites/flag-enemy.png` | `$8752-$8795` | 68 | `SprFlagEnemy`, `SprFlagEnemyRows` | 11 x 3 | 43 (86) | the enemy's flag, building type 8 | NE |
| `gfx/sprites/flag-enemy-odd.png` | `$8796-$87EF` | 90 | `SprFlagEnemyOdd`, `SprFlagEnemyOddRows` | 11 x 4 | 43 (87) | the enemy's flag, building type 8 | NE |
| `gfx/sprites/warbase-sign.png` | `$87F0-$8857` | 104 | `SprWarbaseSign`, `SprWarbaseSignRows` | 17 x 3 | 44 (88) | the warbase sign, building type 0 | NE |
| `gfx/sprites/warbase-sign-odd.png` | `$8858-$88E1` | 138 | `SprWarbaseSignOdd`, `SprWarbaseSignOddRows` | 17 x 4 | 44 (89) | the warbase sign, building type 0 | NE |
| `gfx/sprites/shot-cannon-x.png` | `$88E2-$8923` | 66 | `SprShotCannonX`, `SprShotCannonXRows` | 16 x 2 | 45 (90) | cannon shell, flying along X | NE |
| `gfx/sprites/shot-cannon-x-odd.png` | `$8924-$8965` | 66 | `SprShotCannonXOdd`, `SprShotCannonXOddRows` | 16 x 2 | 45 (91) | cannon shell, flying along X | NE |
| `gfx/sprites/shot-cannon-y.png` | `$8966-$89B5` | 80 | `SprShotCannonY`, `SprShotCannonYRows` | 13 x 3 | 46 (92) | cannon shell, flying along Y | NE |
| `gfx/sprites/shot-cannon-y-odd.png` | `$89B6-$8A05` | 80 | `SprShotCannonYOdd`, `SprShotCannonYOddRows` | 13 x 3 | 46 (93) | cannon shell, flying along Y | NE |
| `gfx/sprites/shot-missile-x.png` | `$8A06-$8A8B` | 134 | `SprShotMissileX`, `SprShotMissileXRows` | 22 x 3 | 47 (94) | missile, flying along X | NE |
| `gfx/sprites/shot-missile-x-odd.png` | `$8A8C-$8B3D` | 178 | `SprShotMissileXOdd`, `SprShotMissileXOddRows` | 22 x 4 | 47 (95) | missile, flying along X | NE |
| `gfx/sprites/shot-missile-y.png` | `$8B3E-$8BC3` | 134 | `SprShotMissileY`, `SprShotMissileYRows` | 22 x 3 | 48 (96) | missile, flying along Y | NE |
| `gfx/sprites/shot-missile-y-odd.png` | `$8BC4-$8C75` | 178 | `SprShotMissileYOdd`, `SprShotMissileYOddRows` | 22 x 4 | 48 (97) | missile, flying along Y | NE |
| `gfx/sprites/shot-phaser-x.png` | `$8C76-$8CDD` | 104 | `SprShotPhaserX`, `SprShotPhaserXRows` | 17 x 3 | 49 (98) | phaser beam, along X | NE |
| `gfx/sprites/shot-phaser-x-odd.png` | `$8CDE-$8D45` | 104 | `SprShotPhaserXOdd`, `SprShotPhaserXOddRows` | 17 x 3 | 49 (99) | phaser beam, along X | NE |
| `gfx/sprites/shot-phaser-y.png` | `$8D46-$8DBF` | 122 | `SprShotPhaserY`, `SprShotPhaserYRows` | 20 x 3 | 50 (100) | phaser beam, along Y | NE |
| `gfx/sprites/shot-phaser-y-odd.png` | `$8DC0-$8E39` | 122 | `SprShotPhaserYOdd`, `SprShotPhaserYOddRows` | 20 x 3 | 50 (101) | phaser beam, along Y | NE |
| `gfx/sprites/ship.png` | `$8E3A-$8F2B` | 242 | `SprShip`, `SprShipRows` | 30 x 4 | 0 (0, 38, 39, 40, 41) | the player's ship | NE |
| `gfx/sprites/ship-odd.png` | `$8F2C-$901D` | 242 | `SprShipOdd`, `SprShipOddRows` | 30 x 4 | 0 (1) | the player's ship | NE |
| `gfx/sprites/shadow.png` | `$901E-$90AF` | 146 | `SprShadow`, `SprShadowRows` | 24 x 3 | 1 (2) | the ship's shadow on the ground | NE |
| `gfx/sprites/shadow-odd.png` | `$90B0-$9171` | 194 | `SprShadowOdd`, `SprShadowOddRows` | 24 x 4 | 1 (3) | the ship's shadow on the ground | NE |
| `gfx/sprites/stones-a.png` | `$9172-$91F1` | 128 | `SprStonesA`, `SprStonesARows` | 21 x 3 | 2 (4, 5) | stones, map type 2 | NE |
| `gfx/sprites/stones-b.png` | `$91F2-$9277` | 134 | `SprStonesB`, `SprStonesBRows` | 22 x 3 | 3 (6, 7) | stones, map type 3 | NE |
| `gfx/sprites/stones-c.png` | `$9278-$92F7` | 128 | `SprStonesC`, `SprStonesCRows` | 21 x 3 | 4 (8, 9) | stones, map type 4 | NE |
| `gfx/sprites/stones-d.png` | `$92F8-$9371` | 122 | `SprStonesD`, `SprStonesDRows` | 20 x 3 | 5 (10, 11) | stones, map type 5 | NE |
| `gfx/sprites/rocks-a.png` | `$9372-$9409` | 152 | `SprRocksA`, `SprRocksARows` | 25 x 3 | 8 (16, 17) | rocks, map type 8 | NE |
| `gfx/sprites/rocks-b.png` | `$940A-$94A7` | 158 | `SprRocksB`, `SprRocksBRows` | 26 x 3 | 9 (18, 19) | rocks, map type 9 | NE |
| `gfx/sprites/rocks-c.png` | `$94A8-$9533` | 140 | `SprRocksC`, `SprRocksCRows` | 23 x 3 | 10 (20, 21) | rocks, map type 10 | NE |
| `gfx/sprites/rocks-d.png` | `$9534-$95C5` | 146 | `SprRocksD`, `SprRocksDRows` | 24 x 3 | 11 (22, 23) | rocks, map type 11 | NE |
| `gfx/sprites/trench-start-y.png` | `$95C6-$963F` | 122 | `SprTrenchStartY`, `SprTrenchStartYRows` | 20 x 3 | 12 (24) | trench start along Y (map type 12 on even rows) | NE |
| `gfx/sprites/trench-start-x.png` | `$9640-$96E9` | 170 | `SprTrenchStartX`, `SprTrenchStartXRows` | 21 x 4 | 12 (25) | trench start along X (map type 12 on odd rows) | NE |
| `gfx/sprites/trench-middle-y.png` | `$96EA-$9775` | 140 | `SprTrenchMiddleY`, `SprTrenchMiddleYRows` | 23 x 3 | 13 (26) | trench middle along Y (map type 13 on even rows) | NE |
| `gfx/sprites/trench-middle-x.png` | `$9776-$981F` | 170 | `SprTrenchMiddleX`, `SprTrenchMiddleXRows` | 21 x 4 | 13 (27) | trench middle along X (map type 13 on odd rows) | NE |
| `gfx/sprites/trench-end-y.png` | `$9820-$98AB` | 140 | `SprTrenchEndY`, `SprTrenchEndYRows` | 23 x 3 | 14 (28) | trench end along Y (map type 14 on even rows) | ZS: rows 8-15 redrawn (`$9856-$987F`) |
| `gfx/sprites/trench-end-x.png` | `$98AC-$9913` | 104 | `SprTrenchEndX`, `SprTrenchEndXRows` | 17 x 3 | 14 (29) | trench end along X (map type 14 on odd rows) | NE |
| `gfx/sprites/block-low.png` | `$9914-$9A15` | 258 | `SprBlockLow`, `SprBlockLowRows` | 32 x 4 | 15 (30) | low block, map type 15 | NE |
| `gfx/sprites/block-low-odd.png` | `$9A16-$9B17` | 258 | `SprBlockLowOdd`, `SprBlockLowOddRows` | 32 x 4 | 15 (31) | low block, map type 15 | NE |
| `gfx/sprites/block-tall.png` | `$9B18-$9C59` | 322 | `SprBlockTall`, `SprBlockTallRows` | 40 x 4 | 16 (32) | tall block with an arch, map type 16 | NE |
| `gfx/sprites/block-tall-odd.png` | `$9C5A-$9D9B` | 322 | `SprBlockTallOdd`, `SprBlockTallOddRows` | 40 x 4 | 16 (33) | tall block with an arch, map type 16 | NE |
| `gfx/sprites/boulders-a.png` | `$9D9C-$9E33` | 152 | `SprBouldersA`, `SprBouldersARows` | 25 x 3 | 6 (12) | boulders, map type 6 | NE |
| `gfx/sprites/boulders-a-odd.png` | `$9E34-$9EF5` | 194 | `SprBouldersAOdd`, `SprBouldersAOddRows` | 24 x 4 | 6 (13) | boulders, map type 6 | NE |
| `gfx/sprites/boulders-b.png` | `$9EF6-$9F8D` | 152 | `SprBouldersB`, `SprBouldersBRows` | 25 x 3 | 7 (14) | boulders, map type 7 | NE |
| `gfx/sprites/boulders-b-odd.png` | `$9F8E-$A04F` | 194 | `SprBouldersBOdd`, `SprBouldersBOddRows` | 24 x 4 | 7 (15) | boulders, map type 7 | NE |
| `gfx/sprites/post.png` | `$A050-$A0E1` | 146 | `SprPost`, `SprPostRows` | 36 x 2 | 21 (42, 43) | border post, map type 21 | NE |
| `gfx/sprites/block-door.png` | `$A0E2-$A1E3` | 258 | `SprBlockDoor`, `SprBlockDoorRows` | 32 x 4 | 17 (34) | low block with a door, map type 17 on even rows | NE |
| `gfx/sprites/block-window.png` | `$A1E4-$A2E5` | 258 | `SprBlockWindow`, `SprBlockWindowRows` | 32 x 4 | 17 (35) | low block with a window, map type 17 on odd rows | NE |
| `gfx/sprites/block-grid.png` | `$A2E6-$A427` | 322 | `SprBlockGrid`, `SprBlockGridRows` | 40 x 4 | 18 (36) | tall block with a grid face and a door, map type 18 on even rows | NE |
| `gfx/sprites/block-dotted.png` | `$A428-$A569` | 322 | `SprBlockDotted`, `SprBlockDottedRows` | 40 x 4 | 18 (37) | tall block with a dotted face, map type 18 on odd rows | ZS: top line blanked (`$A562-$A568`) |
