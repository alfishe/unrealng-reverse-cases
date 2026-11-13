# Screens

| File | Address | Bytes | What | Format |
| --- | --- | --- | --- | --- |
| `loading.png` | `$4000` (side A block 5, bit-reversed on the tape) | 6912 | the loading screen | indexed PNG 256 x 192: index = flash x 32 + ink x 16 + bright x 8 + colour, so each cell's attribute comes back from the picture; a one-colour cell's hidden colour is in the PNG text chunk `rd2` |
