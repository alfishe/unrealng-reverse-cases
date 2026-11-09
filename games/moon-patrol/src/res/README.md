# Resources

Every resource out of the code, in an editable format; `tools/res_formats.py build` turns them back into the bytes
the source INCBINs, `tools/res_formats.py check` proves the round trip (`--against work/mkgame/res`: equal to the
bytes kit/mkgame.py cut from the image). Each folder's README lists its files: address, size, format, readers.

| Folder | What | Format | Files |
| --- | --- | --- | ---: |
| [graphics](graphics/README.md) | graphics A and B: the title logo, the sprites, the scenery strips | indexed PNG sheets | 30 |
| [fonts](fonts/README.md) | the three fonts of the print code | indexed PNG sheets | 3 |
| [text](text/README.md) | every print string | UTF-8 text with the control codes in braces | 31 |
| [courses](courses/README.md) | the Beginner and Champion course scripts | text, one command a line | 2 |
| [tune](tune/README.md) | the tune | text, one word a line | 1 |

Not resources, kept as documented data in the source: the leftovers `$60F8-$6131` (leftover.asm), `$7FBF-$7FFF`
(interrupt.asm), `$BEF0-$BEF7` (courses.asm), `$FFF7-$FFFE` (printing.asm); the tables (the sprite table, the pixel
and screen line tables, the print code table), the variables and the hi-score tables.
