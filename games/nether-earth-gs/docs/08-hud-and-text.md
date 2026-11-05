# 8. HUD and text

What the player reads: the game's own strings, panel and font, and every text file or long text on the three media.
The game's part rests on the byte compare of `neart001` with Nether Earth's image (stage 1, `byte-diff-ne.txt`) and
on the source (`src/game/`); the media texts on the build, which turns each UTF-8 copy back into its exact bytes.

## 8.1 The game's texts are Nether Earth's

The conversion changed 159 bytes of Nether Earth's game, all of them sound code ([9.5](09-sound.md)) and the one
sprite byte at `$A569` ([`src/res/game/README.md`](../src/res/game/README.md)). No string, no panel layout, no
glyph and no number printer changed: the menus, the status panel, the clock, the order names and the radar are
Nether Earth's, at Nether Earth's addresses, and so is the English. They are described in full in
[Nether Earth's doc 8](../../nether-earth/docs/08-hud-and-text.md):

- the print routine `PrintInline` (`$D42D`) with its inline position and colour codes;
- the font (`src/res/game/gfx/font.png`, 64 glyphs from code `$20`);
- every string: the main menu, the redefine screen, the robot menus, the construction menu, the save prompt;
- the status panel, the clock, the number printers and the radar.

In the source the strings stay where the code prints them (`DEFM` after `CALL PrintInline` in
`src/game/robotmenu.asm`, `mainmenu.asm`, `construction.asm`, `screen.asm`), and the nine order names are a resource,
[`src/res/game/text/order-names.txt`](../src/res/game/text/order-names.txt). The GS conversion added no text to the
game: its name "GS-512" is only on the loading screen ([6.2](06-rendering.md)).

## 8.2 The texts on the media

Every text file or long text on the SCL, the TRD and the TAP, as readable Markdown (layout restored, English where
the original is not) and as the UTF-8 build resource in [`src/res/text/`](../src/res/text/README.md):

| Text | Medium | Where | Language | Build resource |
| --- | --- | --- | --- | --- |
| [disk-basic](texts/disk-basic.md) | SCL, TRD | the BASIC `neart GS` (67 bytes) | English (BASIC) | `disk-basic.txt` |
| [tape-basic](texts/tape-basic.md) | TAP | Hood's BASIC `NetherE GS` (961 bytes): his credit, music ON / OFF | English (BASIC) | `tape-basic.txt` |
| [trd-boot-menu](texts/trd-boot-menu.md) | TRD | the boot menu "Work Loader v1.2" by TRON, its 10 strings | English, CP866 | `trd-boot-menu.txt` |
| [trd-boot-hrum-credit](texts/trd-boot-hrum-credit.md) | TRD | HRUM 3.5's credit in `boot` | English | `trd-boot-hrum-credit.txt` |
| [trd-neart482-scroller](texts/trd-neart482-scroller.md) | TRD | `Neart482`'s intro scroller, 2059 characters | Russian (Latin transliteration), with English | `trd-neart482-scroller.txt` |
| [trd-neart482-sector-note](texts/trd-neart482-sector-note.md) | TRD | the note in `Neart482`'s BASIC sector: "KIDSON OF RAPEWARE CORP. PRESENTS" | English | `trd-neart482-sector-note.txt` |
| [trd-neart482-hacked](texts/trd-neart482-hacked.md) | TRD | " HACKED BY KIDSON OF RAPEWARE " at `$89F7` (nothing reads it) | English | `trd-neart482-hacked.txt` |
| [media-trd-sector9](texts/media-trd-sector9.md) | TRD | the credits of ZX Spectrum Navigator 1.10 in sector 9, and the disk label | English | `media-trd-sector9.txt`, `media-trd-label.txt` |
| [media-trd-leftovers](texts/media-trd-leftovers.md) | TRD | the words in the sector tails and the free sectors (old catalogues of the author's disks) | file names | bytes in `src/res/media/` |

The SCL has no text of its own beyond the BASIC; the tape's only text is Hood's BASIC. The words on the loading
screen ("NETHER EARTH", "GS-512", "TRON 2002") are pixels, described in
[`src/res/screen/README.md`](../src/res/screen/README.md).
