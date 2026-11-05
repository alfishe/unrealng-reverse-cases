# Music

The 48K's beeper title tune and the GS conversion's modules.

The title tune as text. `tools/res_tune.py` turns `titletune.tune.txt` into the bytes the source INCBINs
(`music/titletune.bin`, `$FF01-$FFD3`, 211 bytes) and back; `tools/res_formats.py check` proves both ways, and
`python3 tools/res_tune.py check FILE.bin` does it for one file of bytes.

| File | Address | Size | Format | Reader |
| --- | --- | --- | --- | --- |
| `titletune.tune.txt` | `$FF01-$FFD3` | 211 | 27 periods, 7 pattern pointers, 4 patterns (below) | TitleTune `$B446`, from CreditsPage `$B095`: in the GS never played (the installer points that CALL at KeyWait; the title module plays instead), the bytes stay in the image |

## The format

```
periods 0 242 231 ...     TunePeriods $FF01: the period of note n, in passes of the tone loop
order A A B A C C D       TuneOrder $FF1C: the patterns in play order (7 pointers)
pattern A                 a pattern: L<n> sets the note length, a number plays that note
  L1 7 6
  L2 4
end                       the pattern's $FF
```

The patterns are laid out in the text's order right after the order table, so a pattern may grow or shrink; the
code reads exactly 27 periods and 7 order entries. Lines from `#` on are comments; the header and the table of note
frequencies are written again on every install.

## How the player sounds it

TitleTune (`$B446`) runs with the interrupts off. A length command `$C0+n` (`L<n>`) sets the note to n x 16 x 256
passes of the tone loop (`$B486-$B49B`, 81 T a pass, so `L1` is 0.095 s on a 48K). A note byte n takes p =
TunePeriods[n] and runs two counters, p and p + 1 passes; each counter's wrap flips the speaker bit (both at once flip
it once). So a note is two square waves a pass apart, about 3500000 / (2 x 81 x p) Hz, with a slow beat between them:
note 1 (p = 242) is about 89 Hz, note 26 (p = 54) about 400 Hz; the periods fall by about a semitone a step. Between
notes the player checks fire (TitleFireCheck `$A748`) and the keys 1-5; either ends the tune.

The four patterns: A (three times) the theme, B the climbing arpeggios, C (twice) an ostinato of 16 quavers, D the
closing phrase. Notes 3, 15, 22, 24 and 26 are never played (a c1 recording reads only the other periods).

## The GS modules

`level01.mod` .. `level13.mod`: the 13 ProTracker modules (`M.K.`, 31 samples) the loader streams to the card,
one a level, 13 the title's. Each file is the module byte for byte as the card receives it (the stream was
compared with the live port traffic in stage 1). `tools/disk_media.py build` copies them to `build/res/music/*.bin`;
`tools/mkdisk.py` pads each to a whole sector, cuts it into 16384-byte parts and packs a part with Trush when that
is safe and smaller (the rule in [3](../../docs/03-build-and-load.md)). Any tracker that saves ProTracker
`M.K.` modules (OpenMPT, MilkyTracker) edits them. Their titles and sample names: [docs/texts/modules.md](../../docs/texts/modules.md).

| File | Plays | Bytes | Volume (`ModuleVolumes`, `#2A`) |
| --- | --- | ---: | --- |
| `level01.mod` | level 1 | 59392 | `$1A` (26 of 64) |
| `level02.mod` | level 2 | 42496 | `$20` (32 of 64) |
| `level03.mod` | level 3 | 37376 | `$3C` (60 of 64) |
| `level04.mod` | level 4 | 40960 | `$28` (40 of 64) |
| `level05.mod` | level 5 | 56320 | `$40` (64 of 64) |
| `level06.mod` | level 6 | 28672 | `$20` (32 of 64) |
| `level07.mod` | level 7 | 54016 | `$40` (64 of 64) |
| `level08.mod` | level 8 | 44544 | `$20` (32 of 64) |
| `level09.mod` | level 9 | 53910 | `$40` (64 of 64) |
| `level10.mod` | level 10 | 26368 | `$20` (32 of 64) |
| `level11.mod` | level 11 | 41216 | `$20` (32 of 64) |
| `level12.mod` | level 12 | 48128 | `$26` (38 of 64) |
| `level13.mod` | the title pages | 51456 | `$40` (64 of 64) |
