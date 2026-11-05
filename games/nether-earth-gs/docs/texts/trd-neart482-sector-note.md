# trd-neart482-sector-note

**What it is.** A note KIDSON of RAPEWARE CORP. left in the BASIC sector of their intro: the date and the title,
in the bytes past the program's end. Nothing reads it.

**The file.** The TRD's file `Neart482`, sector 0, offset `$98-$D7` (64 bytes; the program and its autostart mark
end at `$77`, zeros around the note): `SectorNote` in `src/trd/neart482/neart482.asm`. ASCII, four fields of 8, 24,
8 and 24 characters with nothing between them. Build input:
[`src/res/text/trd-neart482-sector-note.txt`](../../src/res/text/trd-neart482-sector-note.txt), one field a line,
encoded by `tools/trd_text.py`. English, no translation needed.

## The original

```text
10.12.95
KIDSON OF RAPEWARE CORP.
PRESENTS
NEW INTRO FOR NEW PROG'S
```

10.12.95 is 10 December 1995, the month the scroller signs ([trd-neart482-scroller](trd-neart482-scroller.md)).
