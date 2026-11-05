# src/res/music99: the intro tune of the '99 music block

The music block (`src/music99/music.asm`, `$C000-$CCFF`, sectors 32-44 of `NEZSEd99.B`) is a compiled Sound Tracker
1.x player followed by its module. Both files go into `build/front99/res/music99/` unchanged and
`src/music99/music/player.asm` INCBINs them.

| File | Bytes it stands for | Size | Format | Who reads it |
| --- | --- | ---: | --- | --- |
| `ne_mus.stc` | `Module` `$C4A8-$CC8E` | 2 023 | Sound Tracker module (`.stc`): 27-byte header ("SONG BY ST COMPILE", tempo 6), 99-byte samples, positions at `+$26D`, ornaments at `+$292`, patterns at `+$358` | `InitModule` `$C062` (from `Init` `$C00B`), then `PlayFrame` `$C19D` every interrupt |
| `leftover-cc8f.bin` | `SectorSlack` `$CC8F-$CCFF` | 113 | raw bytes | nobody: pattern bytes of another tune left in memory when the block was saved |

`ne_mus.stc` opens in any STC player or editor (zxtune reads it as 18 positions, 6 912 frames, 138 s). An edited
module must keep its size (2 023 bytes), or `SectorSlack` moves and the block no longer matches the original; the
player takes the module's own offsets, so a different size assembles and plays.
