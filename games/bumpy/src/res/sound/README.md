# Sound

| File | Address | Bytes | What |
| --- | --- | ---: | --- |
| `ay-images.csv` | SfxLandParams `$F3CF`, SfxHitParams `$F3E6`, ... SfxTimerTickParams `$F500` (16 bytes after each effect's `LD HL`) | 14 × 16 | each effect's AY-3-8912 register image: tone periods A, B, C, noise, mixer, volumes A, B, C, envelope period and shape (R0-R13), then two zeros |

The block is the one WriteAyRegisters `$F190` (never called) would write to the chip; the 48K effects pass it in HL to
a beeper primitive that ignores it, except RomNoise, which uses the address's low byte `$E6` as its start in the ROM
([doc 9, 9.5](../../../docs/09-sound.md#95-the-ay-blocks-and-the-128k-code-nobody-runs)). The table keeps the bytes
whole: the chip takes 12 bits of a tone period and 5 of the noise, so water-drop's tone B 4500 plays as 404.
`tools/res_formats.py` writes the table from the 14 resources of the game's `.ann` (`@res sound/ay-<effect>.bin`) and
builds them back.
