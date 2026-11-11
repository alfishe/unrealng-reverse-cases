# Texts

| File | Address | Size | Read by |
| --- | --- | --- | --- |
| options.txt | bank 6 `$F93F-$F9C2` | 132 | the control selection screen: PrintString `$6FB3` through OptionLines `$F935` |

The text is UTF-8: the characters `$20-$7E` as themselves, every other byte as `{XX}` (also `{` and `}`). A line
break is written before a control code that follows a character and ignored when the text is read back. PrintString's
bytes: below `$20` a control code (table ControlCodes `$6F8F`), `$20-$81` a character of Font8x8, `$82` and above a
token (a string from the word table `$9860`), `$FF` the end. The control codes and their operand bytes:

| Code | Operands | Routine |
| --- | --- | --- |
| 0 | column | CodeColumn `$6EA7` |
| 1 | row | CodeAt `$6EB3` |
| 2 | row, column | CodeAtColumn `$6EAE` |
| 3 | - | CodeNumberA `$6EFB`: A as three digits |
| 4 | - | CodeHex `$6F17`: A as two hex digits |
| 5 | 1 | CodeSmallChars `$6DA6`: the small font |
| 7 | - | CodeSmallFont `$6DA1` (then CodeAt) |
| 8 | address | CodeNumber `$6EF1`: the byte there as three digits |
| 9 | margin | CodeLeftMargin `$6F79` |
| 10 | - | SmallNewLine `$6F67` |
| 11 | - | CodeNewLine `$6F4D` |
| 12 | - | CodeMarginHere `$6F80` |
| 13 | attribute | CodeInk `$6F88` |

The other codes: ControlCodes `$6F8F` in src/game (18 words, 4 of them zero).

The other texts stay data entries beside the code that prints them, because they are interleaved with other data
(src/bank6/*.asm: password `$C53E`, catalogue `$C8A0-$C977`, the failure reasons `$CC94-$CD1D`, messages
`$D3EA-$D417`, the final score `$D418-$D4A4`, the weapon descriptions `$D6DA-$D935` between the bar shapes, the
cargo weights `$D936-$D9B1`, the map legends `$DAA1`, `$DAE1`; bank 0 failure texts `$CCAB`, `$CCBE`, `$CCD8`,
`$CCED`). The bank 6 texts also hold the disk version's "INCORRECT DISK" / "INSERT DISK".
