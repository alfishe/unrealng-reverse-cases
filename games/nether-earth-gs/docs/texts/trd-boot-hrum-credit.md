# trd-boot-hrum-credit

**What it is.** The credit of the packer HRUM 3.5 (Dmitry Pyankov, Gorno-Altaisk, 9 January 1997), which the packer
writes after the self-extracting blocks it makes. Nothing reads it; the block's depacker stops before it.

**The file.** The TRD's file `boot`, file offset `$0C13-$0C61` (79 bytes), right after the HRUM stream of the menu's
block (`src/trd/boot/boot.asm`, `HrumCredit`); the rest of the sector after it is `$CD` filler. ASCII; each line ends
with a byte with bit 7 set: `$80` the first two, `$81` the last. Build input:
[`src/res/text/trd-boot-hrum-credit.txt`](../../src/res/text/trd-boot-hrum-credit.txt) (the end bytes as `\x80`,
`\x81`), encoded by `tools/trd_text.py`. English, no translation needed.

## The original

```text
HRUM v3.5 by Dmitry Pyankov
Tel.(38822)-4421-1.Bye!!!
 Gorno-Altaisk, 09.01.97
```

The phone number is as the packer wrote it in 1997 ((38822) is Gorno-Altaisk's dialling code).
