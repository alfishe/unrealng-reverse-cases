# Blocks

| File | Address | Size | Readers |
| --- | --- | --- | --- |
| `rex1.csv` | REX 1 `$6CE0` (BlockDefs) | 2304 | DrawRoom `$C745` |
| `rex2.csv` | REX 2 `$6F06` | 2304 | DrawRoom |
| `demo.csv` | DEMO `$6F38` | 2304 | DrawRoom |

The 256 blocks, 9 character codes each: `c0`-`c2` the top row, `c3`-`c5` the middle, `c6`-`c8` the bottom. The
characters are chars/PART.png. CSV with a header; the first column numbers the blocks and is not read back.
