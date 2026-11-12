# Tables

Text, written and read by `tools/res_tables.py`: `#` starts a comment, a word ending in `:` is a row label, `$XX` is
hex, a plain number decimal, `%bbbbb` binary. Each file's header says what its numbers are.

| File | Entry | Bytes | Form | Readers |
| --- | --- | ---: | --- | --- |
| `logo-attrs.txt` | LogoAttributes `$AC20` | 100 | 5 rows of 20 attributes | DrawScreen `$6510` (to `$5806`) |
| `corner-colours.txt` | CornerColours `$ADF4` | 5 | 5 attributes | ColourCornerRows, ColourCornerColumns |
| `stars.txt` | StarsA `$AC84`, StarsB `$ACFC`, StarsC `$AD74` | 360 | 60 lines `x y lit` (the 6-byte record follows from them: the screen address, the RES / SET / BIT opcodes of the bit, lit); a record that does not fit is `raw:` | SampleStars, MoveStars |
| `keys.txt` | KeyTable `$6B53` | 24 | `letter: row %mask` (row 0-7 the half-row, mask the key's bit) | ReadKeyboard `$6864` |
| `phase-order.txt` | PhaseOrder `$6ADD` | 32 | the phase number of each step | PrintRombPhase `$64DA` |
| `rhombus-columns.txt` | RombColumnOrder `$6B74` | 40 | column numbers 0-39 | Start (to RombColumns `$7600`), BuildRombPhases `$62F1` |
| `rhombus-offsets.txt` | RombPhaseOffsets `$6B9C` | 9 | start columns (index 0 not read) | Start (to RombOffsets `$765C`), BuildRombPhases |
| `exit-sound.txt` | ExitSound `$6E64` | 14 | `Rn: value`, AY registers 0-13 | PlayBell `$6E48` |
| `randoms.txt` | Randoms `$ADEC` | 8 | 4 pairs of numbers | DrawTwinkle `$6BFD`; NewRandoms `$6BAB` refills it |
