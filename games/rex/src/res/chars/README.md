# Room characters

| File | Address | Size | Readers |
| --- | --- | --- | --- |
| `rex1.png` | REX 1 `$63E0` CharGraphics (2048), `$6BE0` CharAttrs (256) | 2304 | DrawRoomCell `$C7E2`, the animated cells |
| `rex2.png` | REX 2 `$6606`, `$6E06` | 2304 | DrawRoomCell, the animated cells |
| `demo.png` | DEMO `$6638`, `$6E38` | 2304 | DrawRoomCell, the animated cells |

The 256 characters the rooms are built of, 8 bytes each, each with its attribute: a colour sheet of 16 a row, a grey
line between them. The palette and `tx-cells` are as in screens/README.md (a cell of one colour keeps its attribute
in `hidden`). A block (blocks/) is 3 x 3 of them; their cell types are tables/*-char-flags.csv. The main loop rolls
or rotates some of them in place every pass (the `AnimChar` labels of the .ann), so the PNG shows their first frame.
