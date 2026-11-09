# Resources

Every resource out of the code, in an editable format; `tools/res_formats.py build` turns them back into the bytes
the source INCBINs, `tools/res_formats.py check` proves the round trip.

| File | What | Format | Entry |
| --- | --- | --- | --- |
| `graphics/BallSprites.png` | the 56 pre-shifted ball sprites | PNG sheet | BallSprites `$D000` |
| `fonts/Font.png` | the font a-z, 0-9 | PNG sheet | Font `$DEF4` |
| `tables/*.csv` | the four physics tables | CSV | ContactTable `$DBFA`, Table8x8 `$DCFA`, FrictionTable `$DD3A`, CollisionRecords `$DE3A` |
| `text/*.txt (14)` | the print records of every page | UTF-8 text | HudTexts `$969D` ... EditorTexts `$C54E` |
| `text/SignatureScript.txt` | the pen script of the signature | text commands | SignatureScript `$DA80` |

Each folder's README.md lists its files with address, size, format and readers. Texts the code builds itself (the
key names, the numbers, the hall of fame names) and the copyright glyph `$9F2E` stay in the code.
