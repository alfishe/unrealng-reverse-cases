# Screens

| File | What | Size | Built into |
| --- | --- | --- | --- |
| `loading.scr` | The loading screen (bitmap and attributes) | 6912 | the tape's block 6, the picy-packed screen |

`tools/picy.py pack build/res/screens/loading.scr build/res` packs it into the three streams the unpacker
`src/tape/picy.asm` INCBINs (3049 literal, 775 mask and 108 flag bytes); the packer is the greedy one the original
used, so the block comes out byte for byte (`tools/picy.py check` proves it). `tools/picy.py unpack` gives the screen
back from the tape's block.
