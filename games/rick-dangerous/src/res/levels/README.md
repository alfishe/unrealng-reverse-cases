# The level data

The game image's `$AF64-$E218` (module `leveldata`), as three text files. `tools/res_levels.py` converts them to
the bytes the sources `INCBIN` and back; `python3 tools/res_formats.py check` proves the round trip.
`python3 tools/fig_rooms.py` draws every zone and every level from these files (`work/stage2/fig/`).

| File | Bytes | Address | Size | Format | Readers |
| --- | --- | --- | --- | --- | --- |
| `levels.txt` | `levels/maps.bin` | `$AF64-$C31B` | 5048 | per zone `map`: rows of 8 tile numbers (hex) | DrawZone `$AD5A` |
| | `levels/zones.bin` | `$D55C-$D649` | 238 | `zone LxZy set S`: 34 records of 7 bytes (+0 char set, +1-2 map, +3-4 exits, +5-6 objects); the pointers follow from the layout | EnterZone `$AC83`; the level table `$E4AE` +8-9 |
| | `levels/exits.bin` | `$D64A-$D7FB` | 434 | `exit SIDE ROW -> ZONE ROW`: 5 bytes (side 0 left / 1 right, map char row, zone record or `$FFFF` = end, the row there); `$FF` after a zone's exits | CheckExit `$AB93` |
| | `levels/objects.bin` | `$D7FC-$DF1C` | 1825 | `obj ROW KIND [taken] flags F x X+D q Q+D`: 5 bytes (row, kind with bit 7 taken, flags, x AND `$F8` + row offset, +4 likewise); `term`: `$FF` and the 4 bytes "term" that end a zone's list | SpawnObjects `$FD7D`; NewGame `$E2DC` clears bit 7 of +1 |
| `tiles.txt` | `levels/tiles.bin` | `$C31C-$D31B` | 4096 | `tile $NN` and 4 rows of 4 char codes (hex) | DrawZone `$AD76` |
| `kinds.txt` | `levels/kinds.bin` | `$D31C-$D55B` | 576 | `kind NAME a b anim script c d`: 72 records of 8 bytes | SpawnObjects `$FD7D`, `$F7C3` (+6, +7 through `$D322`) |
| | `levels/anims.bin` | `$DF1D-$DF82` | 102 | `anim An`: frame bytes, `end` = `$FF` (back to the start) | `$EE0B` |
| | `levels/scripts.bin` | `$DF83-$E218` | 662 | `script Sn`: steps `FRAMES,DX,DY` (signed), `end` = `$FF` | `$EE81` |

**Names.** A zone is `LxZy` (level x, its zone y, in record order). A kind is named by what its record holds, not by
what the player sees: `picK` (kinds 4-21: +2-3 a graphic address, no script), `markK` (22, 23: no graphic, no
script), `actorK` (24-70: an animation list and a movement script), `kindK` (0-3 and 71: zeros; kind 1 has
only +0/+1). `An` and `Sn` are the animation lists and scripts in address order; `kinds.txt` refers to them by name, and
`anim $8F53` is a graphic address outside these files.

**Not decoded.** The meaning of kind +0, +1, +6, +7 (sizes and collision, it seems) and of an object's +4 (bits 3-7
to slot `+$0C`, bits 0-2 a row offset to slot `+$1D`) is known only from the code that copies them; the files keep
them as numbers. The 4 bytes "term" after each object list are never read (the `RES 7` loop of `$E2DC` steps over
them as a record).
