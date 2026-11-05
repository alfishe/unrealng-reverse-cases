# Bytes kept as they are

`src/disk.txt` places each file. These are data or leftovers, not code (the boot BASIC with UltraXOR is built from
`src/boot/`, `tools/ultraxor.py`):

| File | Disk place | Why it is kept |
| --- | --- | --- |
| `nether-n.bin` | `nether.N` | a saved game the authors left on the disk: CODE `$D92B`, 9941 bytes = `$D92B-$FFFF` as the disk module saves it (the game's state to `$FDFB`, then whatever lay above: the HRUM depacker's copy at `$FE4C`, stack words); no checksum. Loaded in recording `work/stage3/r2` (frame 10602): day 29, 10.35, 4 warbases against 3, general resources 99 |
| `filler-*.bin` | after a block's end in its last sector | bytes no read reaches: HRUM's signature (`filler-after-d04`, `filler-after-d05` its first 2 bytes, `filler-after-d06`), older sector contents (`filler-loader-8ce4`, `filler-after-d02`, `filler-fc-d10`, `filler-after-d10`, `filler-after-n`), and the end of `NETHER+.W`'s last sector (`filler-after-w`) |

Zero fillers are `zero` lines in `src/disk.txt`.
