# src/res/trd: the resources of the TRD's extra files

Raw bytes, each INCBIN'd by the source named; the address is where the bytes are when the program uses them. The
texts are not here: they are `src/res/text/trd-*.txt` (UTF-8, converted by `tools/trd_text.py`).

| File | Bytes | Address | Format | Read by |
| --- | --- | --- | --- | --- |
| `boot/sector0-tail.bin` | 80 | boot sector 0 `$B0-$FF` | old memory past the program (the end of an older BASIC line, variables) | `src/trd/boot/boot.asm` |
| `boot/font64.bin` | 1023 | `$8637-$8A35` (run time) | the 64-column font: 8 bytes per pair of codes (`Font + (code >> 1) * 8`), the high nibble the even code, the low the odd; the first byte of each 8 unused; the 1024th byte (`$8A36`, codes 254/255 row 7) is past the unpacked block | `src/trd/boot/print64.asm` (`Font`) |
| `neart481/basic-tail.bin` | 192 | Neart481 sector 2 `$40-$FF` | old memory past the program | `src/trd/neart481/neart481.asm` |
| `neart481/screen-7530.bin` | 3072 | `$7530` | code and the packed loading screen (`ScreenBlock`, sectors 3-14) | `neart481.asm` |
| `neart481/bank6-c000.bin` | 11520 | bank 6 `$C000` | Hrust 1 self-extracting block (sectors 15-59) | `neart481.asm` |
| `neart481/bank3-c000.bin` | 3840 | bank 3 `$C000` | Hrust 1 self-extracting block (sectors 60-74) | `neart481.asm` |
| `neart481/bank4-c000.bin` | 2560 | bank 4 `$C000` | Hrust 1 self-extracting block (sectors 75-84) | `neart481.asm` |
| `neart481/bank1-c000.bin` | 3584 | bank 1 `$C000` | Hrust 1 self-extracting block (sectors 85-98) | `neart481.asm` |
| `neart481/game-61a8.bin` | 18432 | `$61A8` | Hrust 1 self-extracting block: the game (sectors 99-170) | `neart481.asm` |
| `neart482/block-tail.bin` | 137 | `$D7EF-$D877` | old memory after the outer block's RET (the end of sector 111) | `src/trd/neart482/neart482.asm` |
| `neart482/intro-6017.bin` | 6341 | `$6017-$78DB` | the intro's code and data (unpacked) | `src/trd/neart482/intro.asm` |
| `neart482/intro-80e8.bin` | 2319 | `$80E8-$89F6` | the intro's code and data | `intro.asm` |
| `neart482/intro-8a15.bin` | 4651 | `$8A15-$9C3F` | the intro's code and data | `intro.asm` |
| `neart482/inner-61a8.bin` | 40536 | `$61A8-$FFFF` | the inner game, unpacked (packed by `tools/trd_lz.py --raw 2` in the build) | `intro.asm` (as `build/trd/obj/n482-inner.lz`) |
