# The media layouts

| Layout | Written by | Output | Compared with |
| --- | --- | --- | --- |
| `scl.txt` | `tools/mkscl.py` | `build/Zynaps(2In1)(km).scl` | the SCL in `orig/Zynaps(2In1)(km).scl.zip` |
| `trd.txt` | `tools/mktrd.py` | `build/Zynaps(2In1)(km).trd` | the TRD in `orig/Zynaps(2In1)(km).trd.zip` |

The line formats are in the two tools' docstrings. `ZYNAPS.B` is the same on both: the BASIC sector, the depacker
sector, the two packed blocks with the packer's tails. The TRD adds `boot.B`, the label `ZYNAPS  `
(`src/res/media/trd-label.txt`) and sector 9's ten bytes at `$EA`-`$F3`, zeros on this disk (`gap zeros`).
