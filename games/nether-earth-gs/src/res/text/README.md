# The texts

Every text of the loaders and the media as a plain UTF-8 file the build turns back into the exact bytes. A readable
copy of each (layout restored, translated where needed) is in `docs/texts/`.

| File | What | Converted by | Built | Readable copy |
| --- | --- | --- | --- | --- |
| `disk-basic.txt` | the disk's BASIC "neart GS" (67 bytes) | `tools/basic_tok.py` (via `res_media.py`) | `build/res/text/disk-basic.bin` | [disk-basic](../../../docs/texts/disk-basic.md) |
| `tape-basic.txt` | Hood's tape BASIC "NetherE GS" (961 bytes) | `tools/basic_tok.py` (via `res_media.py`) | `build/res/text/tape-basic.bin` | [tape-basic](../../../docs/texts/tape-basic.md) |
| `media-trd-sector9.txt` | the TRD's sector 9 before the disk fields (`$00-$E0`): the copier's signature | `res_media.py` | `build/res/text/media-trd-sector9.bin` | [media-trd-sector9](../../../docs/texts/media-trd-sector9.md) |
| `media-trd-label.txt` | the TRD's label, 8 characters with the trailing space | `tools/mktrd.py` | sector 9 `$F5-$FC` | [media-trd-sector9](../../../docs/texts/media-trd-sector9.md) |
| `trd-boot-menu.txt` | the TRD boot menu's 10 strings (CP866, exact padding) | `tools/trd_text.py` | `build/trd/text/trd-boot-menu.bin` | [trd-boot-menu](../../../docs/texts/trd-boot-menu.md) |
| `trd-boot-hrum-credit.txt` | the HRUM 3.5 credit in the boot (ASCII, lines ended by `$80` / `$81`) | `tools/trd_text.py` | `build/trd/text/trd-boot-hrum-credit.bin` | [trd-boot-hrum-credit](../../../docs/texts/trd-boot-hrum-credit.md) |
| `trd-neart482-scroller.txt` | Neart482's intro scroller (2059 characters, transliterated Russian) | `tools/trd_text.py` | `build/trd/text/trd-neart482-scroller.bin` | [trd-neart482-scroller](../../../docs/texts/trd-neart482-scroller.md) |
| `trd-neart482-sector-note.txt` | the note in Neart482's BASIC sector ("KIDSON OF RAPEWARE CORP.") | `tools/trd_text.py` | `build/trd/text/trd-neart482-sector-note.bin` | [trd-neart482-sector-note](../../../docs/texts/trd-neart482-sector-note.md) |
| `trd-neart482-hacked.txt` | " HACKED BY KIDSON OF RAPEWARE " at `$89F7` (nothing reads it) | `tools/trd_text.py` | `build/trd/text/trd-neart482-hacked.bin` | [trd-neart482-hacked](../../../docs/texts/trd-neart482-hacked.md) |

**BASIC listings** (`tools/basic_tok.py`): one program line a text line, `NUMBER BODY`. A keyword is written by its
name and one space, which belongs to the keyword (a space the program holds after a keyword is a second space). The
hidden 5-byte forms of the numbers are not written: the tokenizer adds them (integer form) after every number
outside `REM`. A byte with no character of its own is `{XX}`. The disk BASIC's `$80 $AA` + line 10 (TR-DOS's
autostart mark) is not in the listing: `src/disk/basic.asm` adds it.

**Sector 9**: ASCII; the NUL bytes are `{00}`, the file has no line end (one line of 225 bytes).

**TRD texts** (`tools/trd_text.py`): the first line names the encoding (`#codec`), each text line ends with `|`, a byte
with no character is `\xNN`. The TRD sources (`src/trd/`) INCBIN the built bytes.
