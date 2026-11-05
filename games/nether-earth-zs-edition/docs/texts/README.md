# The texts of Nether Earth ZS Edition

Readable copies of every long text of both releases: the original Russian with its paragraphs and lists restored from
the layout, then a full English translation. The short strings of the menus and the play screen are not here (the
parts' annotations hold them).

| Page | What it is | Encoding | Size | Where | Shown by |
| --- | --- | --- | ---: | --- | --- |
| [NEabout.W](NEabout.md) | about the edition (ZS, 29.01.1999) | CP866, CR LF | 3 763 bytes, 15 sectors | '99 disk, file 1; page 3 `$C000` | the start-up menu's ABOUT ZS NE |
| [NEdescri.W](NEdescri.md) | the 1987 description translated, the author's notes, a bug warning | CP866, CR LF, TABs | 5 469 bytes, 22 sectors | '99 disk, file 2; page 3 `$CF00` | DESCRIPTION |
| [NEgreets.W](NEgreets.md) | greetings | CP866, CR LF, TABs | 313 bytes, 2 sectors | '99 disk, file 3; page 3 `$E500` | GREETS |
| [NEadvice.W](NEadvice.md) | "Advices of Expert" (Timofey Anisimov) | CP866, CR LF, TABs | 5 572 bytes, 22 sectors | '99 disk, file 4; page 3 `$E700` | ADVICES |
| [NEZSEd99.W](NEZSEd99.md) | the release's readme (ZS, 30.01.1999) | CP866, CR LF, TABs | 5 384 bytes, 22 sectors | '99 disk, file 5 | no program (a text viewer) |
| [The '98 intro scroller](scroller98.md) | greeting, story, the '98 changes (ZS, 23.12.1998) | KOI-7 N2, font switches | 2 312 bytes | '98 intro block `$DAC2-$E3C9` | the '98 intro |
| [The '99 intro scroller](scroller99.md) | keys, greeting, machines, story (ZS, 28.01.1999) | CP866, CR LF, TABs | 4 153 bytes | '99 stage 2 `$654F-$7587` | the '99 intro |

Sizes of the `.W` files are their catalogue lengths; the sectors are what the file takes on the disk.

**The '99 start-up menu has no texts of its own.** Its four text pages (DESCRIPTION, ADVICES, GREETS, ABOUT ZS NE)
show the first four `.W` files, which the 128 K branch of stage 3 reads by disk position into page 3 (the 64 sectors
after `NEZSEd99.B`: the four texts and the first three sectors of the readme) and the menu pages through
([03](../03-build-and-load.md)). On the 48 K path (paging locked) the start-up menu and its texts are not reached.

**The build resources.** The five `.W` files are built from [`src/res/text/`](../../src/res/text/README.md) by
`tools/build_texts.sh` (UTF-8 to CP866 with CR LF, the end mark and the sector slack, byte for byte against the disk).
The two scrollers are parts of packed / code blocks and are built by their parts (intro98, front99); these pages only
read them.

**Conventions.** Lines the author justified to a fixed width (64 columns in the `.W` files, 32 in the '99 scroller)
are joined and the justification spaces are single; words hyphenated at a line end are whole; headings are the
author's centred lines; ASCII art and column layouts are code blocks with TABs expanded to 8 columns. The spelling and
the punctuation are the author's. Translations are full, paragraph by paragraph; the author's emphasis (capitals,
"!!!", smileys) is kept. The claims these texts make are checked against the code in
[01, "The author's claims against the code"](../01-game-design.md).
