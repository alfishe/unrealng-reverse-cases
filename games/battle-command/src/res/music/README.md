# Music

| File | Address | Size | Format | Read by |
| --- | --- | --- | --- | --- |
| tune.txt (`tune.bin`) | bank 4 `$C721-$CB63` | 1091 | the AY player's data as hex in named parts (tools/res_formats.py tune_parts) | the player of src/bank4/music.asm: StartTune `$C000`, MusicTick `$C0D2` |

The parts, in order: OrnamentOffsets `$C721` (7 bytes, each the distance from itself to its ornament), Ornaments
`$C728` (semitone offsets; a byte with bit 7 ends one), Instruments `$C75A` (13 envelope addresses), the 13
instruments (a speed byte, then the volume envelope; `$87` ends one), TuneTable `$C869` (the only tune: speed and the
order lists of channels A, B, C), PatternTable `$C870` (17 words, the last one the end), the three order lists
(codes `$FF`, `$FE`, `$FD`, `$FC`) and the 16 patterns (notes, durations, commands `$80-$93` through CommandOffsets
`$C1C7`, `$B0+` an ornament, `$E0+` an instrument). One tune: the title music.

The catalogue space after it, `$CB64-$E737`, is filled by LoadDirectory on side 2 (src/bank4/music.asm,
CatalogueSpace).
