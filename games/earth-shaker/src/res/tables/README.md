# Tables

CSV: a header line naming the columns, `#` lines comments, numbers decimal or `$hex`, characters quoted. The hex
tables hold attribute bytes, 32 a line (a screen row), `#` lines comments.

| File | Address | Bytes | Readers | What |
| --- | --- | ---: | --- | --- |
| `keys.csv` | `$A900-$A977` | 120 | WaitKey `$8C1D` (for RedefineKeys `$8C30`, EnterName `$7F00`, EnterPassword `$8E2D`) | KeyTable: 40 keys in scan order: half row (the high byte of port `$FE`), bit mask, the character printed (`c` CAPS SHIFT, `s` SYMBOL SHIFT, `e` ENTER) |
| `keyboard-code.csv` | `$EB15-$EB65` | 81 | SaveKeyboardCode `$EB66` (writes), KeyboardControl `$EBCA` (copies back) | KeyboardCode: the 9 bytes of each of the nine key sites as loaded (O, P, Q, A, M): `LD A,row`, `OUT ($FF),A`, `IN A,($FE)`, `AND mask`, `RET NZ` (`JR Z` at the fire site); one site a line, its name and address, the bytes in hex |
| `kempston-code.csv` | `$EAC4-$EB14` | 81 | JoystickControl `$EC2E` | KempstonCode: the joystick version of each site: `NOP` x 4, `IN A,($1F)`, `AND mask`, `RET Z` (`JR NZ` at the fire site) |
| `hiscores.csv` | `$FD14-$FD5E` | 75 | HiScoreCompare `$7F60`, HiScoreInsert `$7F7A`, EnterName `$7F00`, ShowHiScoreTable `$B26C` | HiScoreTable as loaded: 5 records, the score (6 digits, a byte each, 0-9) and the 9-character name: 020000, 016000, 012000, 008000, 004000, all " M.BATTY " |
| `map-attrs.csv` | `$9A80-$9A8F` | 16 | ColourMapCells `$81CC` | MapAttrs: the map screen's attribute of each cell code 0-15 |
| `bar-attrs.txt` | `$BC92-$BCD1` | 64 | BarColours `$9224` | BarAttrs: the time bar's attributes, two rows of 32 |

The nine key sites (TryLeft, TryRight, TryUp, TryDown, KeysStep fire, FireLeft, FireRight, FireUp, FireDown) are
patched in place: RedefineKeys writes the row at +1 and the mask at +7 of each.
