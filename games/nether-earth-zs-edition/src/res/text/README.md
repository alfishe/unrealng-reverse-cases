# src/res/text: the five ZX Word texts of the '99 disk

The `W` files of `NEZSED.SCL` as editable UTF-8 text. `tools/texts_build.py` writes each back in CP866 with CR LF
line ends, adds the end mark and the slack, and `tools/build_texts.sh` writes `build/texts/<NAME>.W` (whole sectors,
as on the disk) and compares them byte for byte with the file's sectors (`work/media/99/files/`, from
`tools/zs_media.py`). `src/disk99.txt` puts them on the disk. The readable copies with translations are in
[`docs/texts/`](../../../docs/texts/README.md).

| File | Disk file | Catalogue length | Sectors | In memory | Who reads it |
| --- | --- | ---: | ---: | --- | --- |
| `NEabout.txt` | `NEabout .W` | 3 763 | 15 | page 3 `$C000` | the start-up menu's ABOUT ZS NE |
| `NEdescri.txt` | `NEdescri.W` | 5 469 | 22 | page 3 `$CF00` | DESCRIPTION |
| `NEgreets.txt` | `NEgreets.W` | 313 | 2 | page 3 `$E500` | GREETS |
| `NEadvice.txt` | `NEadvice.W` | 5 572 | 22 | page 3 `$E700` | ADVICES |
| `NEZSEd99.txt` | `NEZSEd99.W` | 5 384 | 22 | its first 3 sectors at page 3 `$FD00` (read, never shown) | no program: the release's readme |
| `slack/NEdescri.slack.bin` | the last 163 bytes of `NEdescri.W`'s sectors | | | page 3 | none |
| `slack/NEZSEd99.slack.bin` | the last 248 bytes of `NEZSEd99.W`'s sectors | | | not loaded | none |

The catalogue load address of all five is `$9800` (38912), the address ZX Word loads a document at; the game does
not use it: the 128 K branch of stage 3 reads the 64 sectors after `NEZSEd99.B` (the first four texts and three
sectors of the readme) into page 3 by disk position (`docs/03-build-and-load.md`). That is why the sector counts
are fixed: an edited text must stay within its sectors, or every later text moves (the build refuses it).

## Format

- The source is UTF-8 with LF line ends; the disk has CP866 with CR LF. Every character must exist in CP866
  (Cyrillic, Latin, the box-drawing set); TABs stay TABs (the author's indents: ZX Word expands them).
- Two lines keep a trailing space (`NEdescri.txt`, `NEadvice.txt`): an editor that strips trailing spaces breaks the
  byte match.
- The end mark: `NEabout`, `NEdescri`, `NEgreets`, `NEadvice` end with a `$00` byte after the last CR LF, counted in
  the catalogue length; the readme has none. `tools/texts_build.py` adds it (the `TEXTS` table).

## The slack (bytes no program reads)

After the catalogue length the rest of the last sector is zero for `NEabout`, `NEgreets` and `NEadvice`. Two files
keep older bytes there, kept as they are:

- `slack/NEdescri.slack.bin` (163 bytes): `$0D`, 28 spaces, `26.01.1999`, CR LF, then zeros. The tail of an earlier
  save of the description, dated three days before the final one (which ends `29.01.1999`).
- `slack/NEZSEd99.slack.bin` (248 bytes): `$0D $0D`, then a table of 4-byte entries `n 01 00 00` (n = 1 .. 16),
  `$FF` runs, the ASCII `CONVER Commander` and `System  `: a buffer of the PC or Spectrum tool that wrote the disk
  (not identified). The loader stops before these sectors.

An edited text that changes its length must drop or trim its slack file (the build says so) and update the length in
`src/disk99.txt`.
