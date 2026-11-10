# Screen

| File | Address | Bytes | Readers | What |
| --- | --- | ---: | --- | --- |
| `LoadingScreen.png` | `$4000-$5AFF` (tape block 5) | 6912 | LoadBlock `$FEBD` stores it (src/screen/screen.ann); no game code reads it | The loading screen, the Probe / Infogrames title signed "SIMON", 256 x 192 in the 64-colour ink / paper palette. The PNG text chunk `simcity-hidden` keeps the attributes of the cells that are all paper or all ink |

tools/tape.py encrypts it back into block 5 (each byte XOR key XOR the count, the inverse of LoadBlock's store).
