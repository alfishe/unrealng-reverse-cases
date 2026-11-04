# 06. Graphics: the font, the screens, the endings

NE's sprites, view and panel are untouched ([02](02-architecture.md) 3: all 178 sprites at NE's addresses). What
ANE adds is a font, pictures around the game and two ending sequences.

## 1. The game font

NE's font (`$6780`, 64 glyphs, glyph = `$6680 + 8 x code`) is replaced by a Cyrillic one at `$C500-$C6FF` (codes
`$20-$5F`, in NE's freed title-tune place); `PrintChar` and `PrintBigChar` read glyph `$C400 + 8 x code`.
Source: `src/res/gfx/game-font.png` (NE's glyph format, 16 a row; `tools/res_formats.py`). The codes keep NE's
Latin letters where a Russian one looks the same and draw the others over free codes ([08](08-hud-and-texts.md) 1).

## 2. The screens around the game

| Screen | Where | Image |
| --- | --- | --- |
| the Eternity Industry picture | the intro's own HRUM block into bank 7's screen | stage 1 `work/stage1/screens/01-intro-eternity.png` |
| "Presents" | block "Presents", `$6600` | `work/stage2/screens/presents-f1240.png` |
| the scroller | block at `$6600` (bank 4 on the disk) | stage 1 `01-intro-eternity.png` (the scroller line) |
| the title picture: "АДСКАЯ ЗЕМЛЯ", "ADVANCED NETHER EARTH", an armoured figure and a woman, "ETERNITY INDUSTRY PRODUCTION" with the EI logo | sectors 87-99 at `$9C40`: a screen depacker with its data, output to `$4000` | `work/stage2/screens/title-f1450.png` |
| the boot menu, the help pages | the boot program `$6060` | stage 1 `02-boot-menu.png`, `05-help-menu.png`, `06-help-menu-item.png` |
| the game menu picture | drawn by bank 3's code `$E73B`, called from `MenuPicture` (`$67E5`) in place of NE's `PrintTitle` | stage 1 `04-game-menu.png` |

## 3. The endings

Dead End (a lost game, bank 3, entered at `$D2EF`) and Final Cut (a won game, unpacked to `$6060-$F76C`, entered
at `$61A8`) are separate programs with their own tunes ([07](07-sound.md)); Final Cut's text is in
[12](12-claims.md) 4. Their images are kept as bytes (`src/res/img/`); their code is not annotated yet.
