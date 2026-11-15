# Music

`tunes.txt`: Patterns `$C670` to the end of the order lists `$CBA1` (RAM 4), the three tunes as text; the format is
in tools/tunes.py (notes NAME:frames, rests r:frames, commands $XX; order lists pNN). The build reads it.
`instruments.bin`: Instruments `$CBA2-$CF9F`, the envelopes, as bytes.
