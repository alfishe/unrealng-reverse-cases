# src/trd: the TRD's extra files

The TRD (`orig/...[h 2002 Tron Z].trd`) holds three BASIC files the SCL does not: a boot menu and two other
versions of Nether Earth that someone put on the same disk. Each is source here, all its sectors as the TRD holds
them (the tails past the programs too), built and checked by `tools/build_trd_extras.sh`:

| File | TRD place | Sectors | Source | What |
| --- | --- | --- | --- | --- |
| `boot` | track 1 sector 0 | 13 | [boot/](boot/README.md) | TRON's "Work Loader v1.2" (1999): a catalogue menu, HRUM 3.5 packed; RUNs the file chosen |
| `Neart481` | track 103 sector 10 | 171 | [neart481/](neart481/README.md) | a 128K Nether Earth: six packed blocks into four RAM banks, a title tune, a sample |
| `Neart482` | track 114 sector 5 | 112 | [neart482/](neart482/README.md) | KIDSON of RAPEWARE CORP.'s intro (1995) and their Russian Nether Earth |

```sh
sh tools/build_trd_extras.sh [SJASMPLUS]    # build/trd/{boot,Neart481,Neart482}.bin; "trd extras: identical"
```

The resources are in [src/res/trd/](../res/trd/README.md), the texts in `src/res/text/trd-*.txt` with readable copies
in `docs/texts/trd-*.md`. The packers: `tools/hrum.py` (HRUM 3.5, copied from ../advanced-nether-earth),
`tools/trd_lz.py` (Neart482's LZ). The working notes: `work/stage2/NOTES-trd.md`.
