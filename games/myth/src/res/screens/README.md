# Screens: the loading screen

The loading screen as the tape holds it. `.scr` is the Spectrum's own screen format (6144 bytes of bitmap in the
display file's order, then 768 attribute bytes), which every Spectrum paint tool and emulator opens, so it stays the
editable form. src/tape/tape.txt cuts it into its two tape blocks; no `.ann` INCBINs it.

| File | Address | Bytes | Format | Read by |
| --- | --- | ---: | --- | --- |
| loading.scr | bitmap `$4000` (tape block 13), attributes `$8000` (block 15) | 6912 | `.scr`: bitmap `0-$17FF`, attributes `$1800-$1AFF` | the bitmap: LoadStream `$FD2C` straight into the screen (Sl1Start); the attributes: StoreLast's table row 0 to AttrBuffer `$8000`, then AttrReveal `$FC32` copies them to `$5800`, 12 bytes a bit, 64 calls (src/loader/reveal.asm) |

c1: the bitmap appears while block 13 loads, black on black; the colours come in as the attributes are copied.
