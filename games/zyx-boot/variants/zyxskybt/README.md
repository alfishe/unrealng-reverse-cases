# Variant zyxskybt

From `work/candidates/owner-boots_zyx/zyxskybt.scl`, file `ZYXSKYbt` (B, start 201, length 201, 53 sectors). Built by `tools/build.sh --variant zyxskybt`: **identical**.

- Its loader (`basic.txt`, the BASIC as text, `tools/res_basic.py`) reads 1 sector of BASIC, then: `$61A8` x 24, `$A600` x 8, `$BFFB` x 20.
- The music piece at `$BFFB`, 20 sectors, init `$BFFB`; play `$C001`.
- Code: turns the rhombi through a buffer at `$60E0` (`INC DE` for `INC E`: it crosses a page) instead of RotateBuffer `$9C00`, which the scroller's Cyrillic font takes (`sky-rotate-buffer`, tools/variants.py CODE_SWITCHES).
- Code: moves the stars and twinkles around the new picture and scroller: MoveStars goes through SkyStarClip (`$A86D`) and StarStep (at `$6720`, where PrintString was: PrintString moves over the start of the unused DrawReflection, `$6DC6`), the twinkle spots through SkyTwinkleSpot (`$A89E`); no reflection (`sky-stars`, tools/variants.py CODE_SWITCHES).
- Code: hooks the Skynet screen in: DrawScreen calls SkySetup (`$78DD`) where it printed the help text, the interrupt calls SkyFrame (`$A85C`) for the music, the font is at `$A984`, ShowCatalogue has no SoundOff, the bottom rhombi turn on passes with bits 0 and 2 set (`sky-screen`, tools/variants.py CODE_SWITCHES).
- Code of its own, described in `parts/sky.ann` (built by kit/mkgame.py from `parts/sky.json`, placed at `$6FE0`).
- Files that differ from the original: `basic.txt`, `graphics/font-cyrillic.png`, `graphics/logo.png`, `graphics/rhombus.png`, `graphics/sky-picture.png`, `music/player.txt`, `music/stc.txt`, `tables/corner-colours.txt`, `tables/logo-attrs.txt`, `tables/sky-picture-attrs.txt`, `texts/menu-help.txt`, `texts/sky-scroll.txt`.
- The tune: compiled Sound Tracker at `$BFFB` (init `$BFFB`, play `$C001`), as text (`music/stc.txt`, `music/player.txt`); the music index matches its notes to "strackerrmxY" (Yerzmyey and Kicia), three different hits: not identified for sure.
- Skynet Games (Taganrog) edition: the menu's help text gives way to a picture at the bottom of the screen with a scroller of the firm's advertisement in Russian, the logo's pixel rows wave, stars and twinkles keep off the logo and the picture.
- The 9 more sectors at `$6FE0-$79A7` (`parts/sky.ann`, four pieces): the picture, its attributes, the Cyrillic font (`graphics/sky-picture.png`, `tables/sky-picture-attrs.txt`, `graphics/font-cyrillic.png`), the bars run at `$FE0D`, the scroller and its enciphered text run at `$A500` (`texts/sky-scroll.txt`, tools/res_variants.py), the set-up. After `kit/mkgame.py --part ... --install` the four resources land as bytes in `parts/res/`: turn them into the editable files with tools/res_variants.py (res_formats converters) and delete `parts/res/`.
