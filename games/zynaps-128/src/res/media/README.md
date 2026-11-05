# The disk's own bytes

| File | Where | Bytes | What |
| --- | --- | --- | --- |
| `trd-label.txt` | TRD sector 9 `$F5` | 8 | the disk's label, `ZYNAPS  ` |
| `zynapsb-sector0-tail.bin` | `ZYNAPS.B` sector 0, bytes 172-255 (SCL and TRD) | 84 | what followed the program in memory when it was saved: `" LINE 1`, ENTER (the end of the SAVE command's `LINE 1`), `$80` (the edit line's end), then work-space bytes (`ca e7 5e 01 00 00 00 e7 5e 01 00 00 00 01 00`) and zeros. TR-DOS reads the sector whole; nothing uses these bytes |

The packer's tails after the two blocks (the descriptor of the packed file and the packer's signature) are not here:
`tools/hrust1.py pack --file NAME` writes them.
