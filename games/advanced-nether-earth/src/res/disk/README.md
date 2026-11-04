# Bytes kept as they are

`src/disk.txt` places each file. None of these comes from a source yet:

| File | Disk place | Why it is kept |
| --- | --- | --- |
| `boot-a-nether-b.bin` | `A_NETHER.B` sectors 0-10 | the BASIC with UltraXOR v1.2 (Paracels): about 70 small layers, each decrypting the next with keys from the R register and from its own bytes, then a sector reader on TR-DOS ROM gadgets. The build would have to re-encrypt every layer with its key schedule; its effect is documented (docs/03-build-and-load.md 4.2) and the bytes are kept |
| `nether-n.bin` | `nether.N` | a saved game (data, not code) |
| `filler-*.bin` | after a block's end in its last sector | bytes no read reaches: HRUM's signature (`filler-after-d04`, `filler-after-d05` its first 2 bytes, `filler-after-d06`), older sector contents (`filler-loader-8ce4`, `filler-after-d02`, `filler-fc-d10`, `filler-after-d10`, `filler-after-n`), and the end of `NETHER+.W`'s last sector (`filler-after-w`) |

Zero fillers are `zero` lines in `src/disk.txt`.
