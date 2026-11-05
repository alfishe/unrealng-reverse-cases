# src/trd/neart482: the TRD's file Neart482

KIDSON of RAPEWARE CORP.'s intro (December 1995) and their hacked Russian Nether Earth ("КИДСОН 1996!" in the game):
two self-extracting blocks of one LZ packer, one inside the other.

| File | What |
| --- | --- |
| `neart482.asm` | the whole file, 112 sectors: line 1 `RANDOMIZE USR VAL "23881"` with `Loader` (`$5D49`) in the same line, the autostart mark, `SectorNote`; the outer block `Block` (`$6978`); 137 bytes of old memory |
| `intro.asm` | what the outer block unpacks, `$5FB4-$EF2D`: `IntroStart` (`$5FD9`), the intro's bytes, `ScrollerText` (`$78DC`), `HackedNote` (`$89F7`), the inner block `InnerBlock` (`$9C40`) |
| `lzsfx.asm` | the packer's self-extractor (macro `LZ_SFX`): set-up, the 100-byte depacker run at `$5B8D`, the stream, a RET |

The flow: `Loader` blanks the screen, makes TR-DOS's error hook `POP AF; RET`, flashes the border blue, yellow and
green, reads sectors 1-111 to `$6978` and enters `Block` through the TR-DOS ROM (`$1FF3` first). `Block` unpacks the
intro to `$5FB4-$EF2D` and jumps to `IntroStart`; the intro runs under IM 2 until SPACE, then jumps to `InnerBlock`,
which unpacks the game to `$61A8-$FFFF` and jumps to its Start, `$A600`.

**The packer** (`tools/trd_lz.py`: format, depacker, packer). Not named on the disk; no signature. Byte tokens: a
match `0LLLHHHH LLLLLLLL` (3-10 bytes, 1-4095 back), a literal run `10NNNNNN` (1-63; `$80` ends), a run of one byte
`11NNNNNN B` (3-66). The packer leaves the data's last bytes raw (9 for the outer block, 2 for the inner): the
set-up's LDDR puts them in place. Its choices (the longest match, the farthest of equal ones, a run only when longer,
literal runs cut at 63) give both original streams back byte for byte.

The build: `tools/trd_lz.py pack --raw 2` packs `src/res/trd/neart482/inner-61a8.bin` for `intro.asm`; the assembled
intro (`build/trd/obj/n482-outer.bin`) is packed with `--raw 9` for `neart482.asm`.

**Kept as bytes**: the intro's code and data (`intro-6017.bin`, `intro-80e8.bin`, `intro-8a15.bin`; its effect
routines `IntroWait` `$67F8` and `IntroToggle` `$8235` are not analysed) and the inner game (`inner-61a8.bin`, 40536
bytes: Nether Earth with KIDSON's changes, which the scroller lists; the signature base finds ANE's view tail at
`$6731` and robot menu at `$A720` exact, and NE's Start at `$A600` but one byte). Its own texts (Russian in Latin
letters, "0..CTAPT IGPQ" and the like) are inside that resource and not yet written out as text files.
