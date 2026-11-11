# Tiles

The 8 x 8 tiles the rooms are built from. Each PNG is a sheet of colour cells, 16 a row with a grey line between
them, in the palette of src/res/screens/README.md (64 attribute colours and grey): a cell's pixels give the 8 pixel
bytes and its colours the attribute. A cell that is all paper or all ink hides one of its colours: the PNG text chunk
`tx-cells` keeps those attributes (`hidden`).

| File | Address | Bytes | Readers | What |
| --- | --- | ---: | --- | --- |
| `base.png` | TilePixels `$F000-$F7FF`, TileAttrs `$DF00-$DFFF` | 2048 + 256 | DrawRoom `$99A4` (DrawRoomCell `$99AA`), InitGame `$8F69`, CapsulesFrame `$928E`, the flames, SwapTileset `$918D`, SwapTileBitmaps `$919A` | the 256 tiles, tile T at `$F000 + 8 x T`, its attribute at `$DF00 + T` |
| `alt.png` | AltTilePixels `$FA00-$FDFF`, AltTileAttrs `$C580-$C5FF` | 1024 + 128 | SwapTileset `$918D`, SwapTileBitmaps `$919A` | the alternate upper tiles `$80-$FF`, swapped into `$F400`/`$DF80` in the 15 rooms of the `alternate` line of rooms/rooms.txt and swapped back in the next room on the base set |

Tiles `$8C-$8D` (alternate set) are the capsule, animated by CapsulesFrame from graphics/capsules.png; tile `$B5`
(base set) is the flame, animated from graphics/flames.png. Which tiles stop or carry the hero is in
tables/floor-tiles.txt, solid-tiles.txt and their alternate twins.
