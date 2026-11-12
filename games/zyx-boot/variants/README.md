# The variants

One folder a variant of the owner's 39 images (`work/candidates/owner-boots_zyx`; the 18 boots on `zyxboot.scl` are `zyxboot-01` ... `zyxboot-18`). Each holds only what differs from the original: the resource files (same names and formats as `src/res`), its music piece, its BASIC sector when that is not the original's, the disk's other files, and `variant.json` (the music piece's address and entries, the moved work areas, the code switches). `tools/variants.py extract` writes them from the candidates, `tools/build.sh --variant NAME` builds one, `tools/build.sh --all` all of them.

Layout A is the original's code; layout B has one more CALL into the music piece after CALL MusicInit (3 bytes: every later address of the code piece moves by 3, which the labels follow); most B variants also keep the screen copy at `$C000` and its stack at `$BF68`. The code switches are in `tools/variants.py` (`CODE_SWITCHES`); no variant has a copy of the code.

**47 of 56 build identical.**

| Variant | Layout | Files that differ | Code switches and moved areas | Build |
| --- | --- | --- | --- | --- |
| [zyxae](zyxae/README.md) | B | `graphics/rhombus.png`, `music/piece.bin`, `spare/basic-tail.bin` | MenuStack ScreenCopy ScreenCopyHigh | identical |
| [zyxalex](zyxalex/README.md) | B | `graphics/font.png`, `graphics/logo.png`, `graphics/rhombus.png`, `music/piece.bin`, `spare/basic-tail.bin`, `spare/code-tail.bin`, `tables/logo-attrs.txt` | MenuStack Im2Table Im2Jump ScreenCopy ScreenCopyHigh | identical |
| [zyxalex2](zyxalex2/README.md) | A | `graphics/rhombus.png`, `music/piece.bin`, `spare/basic-tail.bin` |  | identical |
| [zyxamebt](zyxamebt/README.md) | B | `graphics/logo.png`, `graphics/rhombus.png`, `music/piece.bin`, `spare/basic-tail.bin`, `tables/logo-attrs.txt` | MenuStack ScreenCopy ScreenCopyHigh | identical |
| [zyxarbt](zyxarbt/README.md) | A | `music/piece.bin`, `spare/basic-tail.bin` | MenuStack | identical |
| [zyxawbt](zyxawbt/README.md) | A | `basic.bin`, `graphics/logo.png`, `graphics/rhombus.png`, `music/piece.bin`, `texts/menu-help.txt` |  | identical |
| [zyxboot-01](zyxboot-01/README.md) | own loader | `basic.bin` |  | its own loader: not built from the source yet |
| [zyxboot-02](zyxboot-02/README.md) | B | `music/piece.bin`, `spare/basic-tail.bin` | MenuStack ScreenCopy ScreenCopyHigh | identical |
| [zyxboot-03](zyxboot-03/README.md) | B | `music/piece.bin`, `spare/basic-tail.bin` | kempston, glint-daa, MenuStack ScreenCopy ScreenCopyHigh | identical |
| [zyxboot-04](zyxboot-04/README.md) | B | `music/piece.bin`, `spare/basic-tail.bin` | kempston, MenuStack ScreenCopy ScreenCopyHigh | identical |
| [zyxboot-05](zyxboot-05/README.md) | A | `basic.bin`, `music/piece.bin`, `spare/code-tail.bin` |  | identical |
| [zyxboot-06](zyxboot-06/README.md) | B | `music/piece.bin`, `spare/basic-tail.bin` | MenuStack ScreenCopy ScreenCopyHigh | identical |
| [zyxboot-07](zyxboot-07/README.md) | B | `music/piece.bin`, `spare/basic-tail.bin` | MenuStack ScreenCopy ScreenCopyHigh | identical |
| [zyxboot-08](zyxboot-08/README.md) | A | `basic.bin`, `music/piece.bin`, `spare/code-tail.bin` |  | identical |
| [zyxboot-09](zyxboot-09/README.md) | own loader | `basic.bin` |  | its own loader: not built from the source yet |
| [zyxboot-10](zyxboot-10/README.md) | A | `music/piece.bin`, `spare/basic-tail.bin` | no-joystick | identical |
| [zyxboot-11](zyxboot-11/README.md) | A | `basic.bin`, `music/piece.bin` |  | identical |
| [zyxboot-12](zyxboot-12/README.md) | A | `music/piece.bin`, `spare/basic-tail.bin` | no-joystick | identical |
| [zyxboot-13](zyxboot-13/README.md) | B | `music/piece.bin`, `spare/basic-tail.bin` | MenuStack ScreenCopy ScreenCopyHigh | identical |
| [zyxboot-14](zyxboot-14/README.md) | A | `basic.bin`, `music/piece.bin`, `spare/code-tail.bin` |  | identical |
| [zyxboot-15](zyxboot-15/README.md) | A | `basic.bin`, `music/piece.bin`, `spare/code-tail.bin` |  | identical |
| [zyxboot-16](zyxboot-16/README.md) | A | `basic.bin`, `music/piece.bin`, `spare/code-tail.bin` |  | identical |
| [zyxboot-17](zyxboot-17/README.md) | A | `basic.bin`, `music/piece.bin`, `spare/code-tail.bin` |  | identical |
| [zyxboot-18](zyxboot-18/README.md) | A | `basic.bin`, `music/piece.bin`, `spare/code-tail.bin` |  | identical |
| [zyxdebt](zyxdebt/README.md) | A | `graphics/logo.png`, `graphics/rhombus.png`, `music/piece.bin`, `spare/basic-tail.bin`, `texts/menu-help.txt`, `texts/no-files.txt` |  | identical |
| [zyxdimob](zyxdimob/README.md) | B | `basic.bin`, `graphics/logo.png`, `graphics/rhombus.png`, `graphics/twinkle.png`, `music/piece.bin`, `texts/menu-help.txt` | kempston, no-music-init, MenuStack ScreenCopy ScreenCopyHigh | identical |
| [zyxermbt](zyxermbt/README.md) | own loader | `basic.bin` |  | its own loader: not built from the source yet |
| [zyxfp](zyxfp/README.md) | A | `graphics/rhombus.png` |  | identical |
| [zyxfp3bt](zyxfp3bt/README.md) | A | `graphics/font.png`, `graphics/logo.png`, `graphics/rhombus.png`, `graphics/twinkle.png`, `music/piece.bin`, `spare/basic-tail.bin`, `spare/code-tail.bin`, `tables/corner-colours.txt`, `tables/logo-attrs.txt` |  | identical |
| [zyxfp4bt](zyxfp4bt/README.md) | A | `graphics/logo.png`, `graphics/rhombus.png`, `music/piece.bin`, `spare/basic-tail.bin`, `tables/corner-colours.txt`, `tables/logo-attrs.txt`, `tables/phase-order.txt` | kempston | identical |
| [zyxfzbt](zyxfzbt/README.md) | A | `basic.bin`, `graphics/rhombus.png`, `music/piece.bin`, `tables/rhombus-columns.txt`, `texts/menu-help.txt`, `texts/no-files.txt` | music-after-screen | identical |
| [zyxgambt](zyxgambt/README.md) | B | `graphics/font.png`, `graphics/logo.png`, `graphics/twinkle.png`, `music/piece.bin`, `spare/basic-tail.bin`, `tables/corner-colours.txt`, `tables/logo-attrs.txt`, `texts/menu-help.txt` | MenuStack ScreenCopy ScreenCopyHigh GlintEdge GlintCentre | identical |
| [zyxhsbt](zyxhsbt/README.md) | A | `graphics/logo.png`, `graphics/rhombus.png`, `music/piece.bin`, `spare/basic-tail.bin`, `tables/logo-attrs.txt` | kempston, glint-add | identical |
| [zyxisl](zyxisl/README.md) | own loader | `basic.bin` |  | its own loader: not built from the source yet |
| [zyxkisbt](zyxkisbt/README.md) | B | `music/piece.bin`, `spare/basic-tail.bin`, `texts/menu-help.txt` | MenuStack ScreenCopy ScreenCopyHigh | identical |
| [zyxkombt](zyxkombt/README.md) | A | `graphics/font.png`, `graphics/logo.png`, `graphics/rhombus.png`, `music/piece.bin`, `spare/basic-tail.bin` |  | identical |
| [zyxlebt](zyxlebt/README.md) | A | `graphics/logo.png`, `graphics/rhombus.png`, `music/piece.bin`, `spare/basic-tail.bin`, `tables/logo-attrs.txt` | kempston | identical |
| [zyxlesbt](zyxlesbt/README.md) | A | `graphics/logo.png`, `graphics/rhombus.png`, `music/piece.bin`, `spare/basic-tail.bin`, `tables/logo-attrs.txt`, `texts/no-files.txt` |  | identical |
| [zyxlgbt](zyxlgbt/README.md) | own loader | `basic.bin` |  | its own loader: not built from the source yet |
| [zyxlogrb](zyxlogrb/README.md) | A | `graphics/logo.png`, `music/piece.bin`, `spare/basic-tail.bin`, `tables/logo-attrs.txt` | kempston, glint-add | identical |
| [zyxm94bt](zyxm94bt/README.md) | A | `graphics/logo.png`, `graphics/rhombus.png`, `music/piece.bin`, `spare/basic-tail.bin`, `texts/menu-help.txt`, `texts/no-files.txt` |  | identical |
| [zyxmassb](zyxmassb/README.md) | A | `graphics/font.png`, `graphics/logo.png`, `graphics/rhombus.png`, `tables/logo-attrs.txt`, `texts/menu-help.txt` |  | identical |
| [zyxmegbt](zyxmegbt/README.md) | B | `graphics/rhombus.png`, `music/piece.bin`, `spare/basic-tail.bin` | MenuStack ScreenCopy ScreenCopyHigh | identical |
| [zyxmixmb](zyxmixmb/README.md) | B | `music/piece.bin`, `spare/basic-tail.bin`, `texts/menu-help.txt` | MenuStack ScreenCopy ScreenCopyHigh | identical |
| [zyxremix](zyxremix/README.md) | own loader | `basic.bin` |  | its own loader: not built from the source yet |
| [zyxrover](zyxrover/README.md) | A | `graphics/rhombus.png`, `music/piece.bin`, `spare/basic-tail.bin`, `spare/code-tail.bin`, `texts/menu-help.txt`, `texts/no-files.txt` |  | identical |
| [zyxrusbt](zyxrusbt/README.md) | A | `graphics/font.png`, `graphics/logo.png`, `graphics/rhombus.png`, `graphics/twinkle.png`, `music/piece.bin`, `spare/basic-tail.bin`, `texts/menu-help.txt`, `texts/no-files.txt` | MenuStack | identical |
| [zyxsdbot](zyxsdbot/README.md) | B | `graphics/rhombus.png`, `music/piece.bin`, `spare/basic-tail.bin`, `texts/menu-help.txt` | MenuStack ScreenCopy ScreenCopyHigh | identical |
| [zyxsdgrp](zyxsdgrp/README.md) | own loader | `basic.bin` |  | its own loader: not built from the source yet |
| [zyxsiriu](zyxsiriu/README.md) | A | `music/piece.bin`, `spare/basic-tail.bin`, `tables/keys.txt`, `texts/menu-help.txt` | no-joystick | identical |
| [zyxskitb](zyxskitb/README.md) | A | `graphics/logo.png`, `graphics/rhombus.png`, `music/piece.bin`, `spare/basic-tail.bin`, `tables/logo-attrs.txt`, `tables/stars.txt`, `texts/menu-help.txt`, `texts/no-files.txt` |  | identical |
| [zyxskybt](zyxskybt/README.md) | own loader | `basic.bin` |  | its own loader: not built from the source yet |
| [zyxslbt](zyxslbt/README.md) | B | `graphics/font.png`, `graphics/logo.png`, `graphics/rhombus.png`, `music/piece.bin`, `spare/basic-tail.bin` | MenuStack ScreenCopy ScreenCopyHigh | identical |
| [zyxtribt](zyxtribt/README.md) | B | `graphics/rhombus.png`, `music/piece.bin`, `spare/basic-tail.bin` | MenuStack ScreenCopy ScreenCopyHigh | identical |
| [zyxtvmbt](zyxtvmbt/README.md) | A | `graphics/rhombus.png`, `music/piece.bin`, `spare/basic-tail.bin`, `spare/code-tail.bin` |  | differs: body offset 273 (code $61B9) |
| [zyxzxtbt](zyxzxtbt/README.md) | B | `music/piece.bin`, `spare/basic-tail.bin`, `texts/menu-help.txt` | MenuStack ScreenCopy ScreenCopyHigh | identical |
