# 8. HUD and text

Status: stage 2. This document lists where the texts of both releases live, in which encoding and font, and links
the readable copies with their English translations ([texts/](texts/README.md)).

## 8.1 The long texts

| Text | Encoding | Where | Shown by | Readable copy | Build source |
| --- | --- | --- | --- | --- | --- |
| `NEabout.W` | CP866, CR LF | '99 disk, page 3 `$C000` | ABOUT ZS NE | [NEabout](texts/NEabout.md) | `src/res/text/NEabout.txt` |
| `NEdescri.W` | CP866, CR LF, TABs | page 3 `$CF00` | DESCRIPTION | [NEdescri](texts/NEdescri.md) | `src/res/text/NEdescri.txt` |
| `NEgreets.W` | CP866, CR LF, TABs | page 3 `$E500` | GREETS | [NEgreets](texts/NEgreets.md) | `src/res/text/NEgreets.txt` |
| `NEadvice.W` | CP866, CR LF, TABs | page 3 `$E700` | ADVICES | [NEadvice](texts/NEadvice.md) | `src/res/text/NEadvice.txt` |
| `NEZSEd99.W` | CP866, CR LF, TABs | the disk only (three sectors read, never shown) | a text viewer (ZX Word) | [NEZSEd99](texts/NEZSEd99.md) | `src/res/text/NEZSEd99.txt` |
| the '98 intro scroller | KOI-7 N2, font switches | '98 intro `$DAC2-$E3B8` | the '98 intro | [scroller98](texts/scroller98.md) | `src/res/intro98/scroll-text.txt` |
| the '99 intro scroller | CP866, CR LF, TABs | '99 stage 2 `$654C-$7586` | the '99 intro | [scroller99](texts/scroller99.md) | `src/res/stage2/scroller.txt` |

Every build source is UTF-8; its part's build writes the original encoding back with the line ends, the end mark
and the sector slack, byte for byte ([src/res/text/README.md](../src/res/text/README.md)). The authors' claims in
these texts are checked against the code in [01](01-game-design.md), 1.10.

## 8.2 The fonts

| Font | Where | Size | Used by | Source |
| --- | --- | --- | --- | --- |
| the game font, '98 | `$6780-$697F` | 64 glyphs of 8 x 8 | the menu, the panel, the messages | NE's bytes (`src/res/game98`) |
| the game font, '99 | `$6780-$697F` | 64 glyphs | the same and the start-up menu's title (size `$31`) | ZS's new design: 347 of 512 bytes differ from NE (`src/res/game99/gfx/font.png`) |
| the '98 intro font | `$E6CC-$E9CB` | 96 glyphs | the scroller, KOI-7 Cyrillic in the lower case places | `src/res/intro98/font.png` |
| the 64-column font | '99 stage 2 `$7587-$7D86` and again in the menu `$DEF1-$E6F0` | 256 glyphs of 4 x 8 in both nibbles, CP866 | the '99 scroller and the start-up menu's text viewer | `src/res/stage2/font64.png`, `src/res/menu99/viewer-font.png` (the same 2048 bytes) |

## 8.3 The panel and the messages

The play panel is Nether Earth's with ZS's changes: the enemy's robot count is blank in the '98 (the print at
`$D2C8` is `NOP`ped) and `??` in the '99 on MEDIUM and up (the level table writes it; EASY shows the count),
GENERAL starts at 99. The end-of-game messages over the radar (`gameturn` module):

| Release | Lost | Won |
| --- | --- | --- |
| '98 | YOU HAVE NO BASES LEFT | WELL DONE! WAIT FOR NEW LEVELS FROM ZS! |
| '99 | YOU HAVE NO BASES LEFT | INSIGNIANS DESTROYED / CONGRATULATIONS! |

The start-up menu's strings are in `src/res/menu99/menu-strings.txt`; the '98 menu's title and items are in its
`mainmenu` module (`src/game98/mainmenu.asm`).
