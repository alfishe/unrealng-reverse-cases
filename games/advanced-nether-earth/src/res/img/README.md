# The unpacked images

Each file is one HRUM block's output as the depacker leaves it (`tools/ane_sim.py --depacks`, then checked: packed
again by `tools/hrum.py` they give the original streams). They are bytes, not yet sources; the build packs them
(`src/sfx/blocks.asm`). docs/03-build-and-load.md 4 has where each lies and what it is.

| File | Unpacks to | What |
| --- | --- | --- |
| `intro-6600.bin` | `$6600-$A3AC` | the intro; `$7537-$7D2C` (its picture's block) is zero here: `src/images.asm` puts the built block there |
| `intro-screen-c000.bin` | bank 7 `$C000-$DAFF` | the Eternity Industry picture (a screen) |
| `d02-6600.bin` | `$6600-$D4A3` | "Presents" |
| `d03-6600.bin` | `$6600-$FFFF` | the credits scroller |
| `d04-c000-bank1.bin` | bank 1 `$C000-$D60E` | the boot music: PT3 player v1.0 and an X-Man tune |
| `d05-6060.bin` | `$6060-$F6D4` | the boot program: the boot menu and the help |
| `d06-c000-bank7.bin` | bank 7 `$C000-$FFFF` | bank 7's image; `$C000-$CE08` (the game starter's block) is zero here: `src/images.asm` puts it there |
| `d07-9c40.bin` | `$9C40-$B78F` | the game starter (unpacks the game's blocks) |
| `plain-9c40.bin` | `$9C40-$A93F`, not packed | the title picture: a screen depacker and its data, sectors 87-99 as they are |
| `music-c000-bank1.bin` | bank 1 `$C000-$E21A` | the game music: Phantom Family's player, X-Man's "TAIGA" |
| `dead-end-c000-bank3.bin` | bank 3 `$C000-$FE1E` | Dead End and the game menu's picture code (`$E73B`) |
| `disk-io-c000-bank4.bin` | bank 4 `$C000-$CD2B` | the disk module |
| `final-cut-6060.bin` | `$6060-$F76C` | Final Cut |

The game's image is not here: it is built from Nether Earth's source and `src/game/ane-patches.asm`.
