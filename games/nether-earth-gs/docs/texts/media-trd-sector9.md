# media-trd-sector9

**What it is.** The credits of ZX Spectrum Navigator 1.10 (a TR-DOS disk tool by Roman Khroupnin, 1997-98) in the
unused part of the TRD's system sector, track 0 sector 9: the tool that formatted or wrote the disk left them;
nothing reads them. The label is the disk's name in the same sector.

**The file.** The TRD `Nether Earth (1987)(...)[h 2002 Tron Z].trd`, track 0 sector 9 (image offset `$800`): the
bytes `$00-$E0` (225: a `$00`, the 215 characters of the text, nine `$00`; ASCII); the label at `$F5-$FC` (8 bytes
ASCII). Build inputs: [`src/res/text/media-trd-sector9.txt`](../../src/res/text/media-trd-sector9.txt) (one line, the
NUL bytes as `{00}`, written back by `tools/res_media.py`) and
[`src/res/text/media-trd-label.txt`](../../src/res/text/media-trd-label.txt) (read by `tools/mktrd.py`). The text is
English, no translation needed. The SCL has no system sector, so neither is in it.

## The original

The text is one run of characters with double spaces between its parts; split there:

```text
ZX Spectrum Navigator
Version 1.10
Copyright (c) 1997,98 RomanRoms Software Co.
Russia. Nizhny Novgorod.
Written by Roman Khroupnin (RomanRom2)
To find me use FIDOnet - 2:5015/97 or Internet - RomanRom2@usa.net
```

The label (with its trailing space):

```text
n-earth 
```

The author's contacts (a FidoNet address and an e-mail) are as the program wrote them in 1998.
