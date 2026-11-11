# Graphics

Small one-bit graphics that are not 24 x 24 sprites. Each PNG is a sheet of cells with a grey line between them,
white = ink; the text chunk `tx-sheet` keeps the layout.

| File | Address | Bytes | Readers | What | Layout |
| --- | --- | ---: | --- | --- | --- |
| `title-logo.png` | TitleLogo `$95FD-$9854` | 600 | MenuFrameSides `$93F5` (the device menu) | the TERRAMEX logo: 3 rows of 25 character cells | 8 x 8 cells, 8 bytes a cell top first, 25 a row |
| `capsules.png` | CapsuleFrames `$92FD-$933C` | 64 | CapsulesFrame `$928E` (copied to `$F460`) | the capsule's four frames, tiles `$8C-$8D`: a frame is the left tile then the right; they differ only in rows 3-6 of the right tile | 8 x 8 cells, 8 bytes top first, 8 a row (2 a frame) |
| `flames.png` | FlameFrames `$933D-$935C` | 32 | RoomEffects `$91E2` (copied to `$F5A8`) | the flame's four frames, tile `$B5`; PassCount AND 3 picks one | 8 x 8 cells, 4 a row |
| `cursor.png` | CursorSprites `$CD8F-$CF0E` (selector, RAM 1) | 384 | DrawCursor `$C314` | the selector's hand cursor: 4 frames pre-shifted by 0, 2, 4, 6 pixels, each with its mask | 24 x 16, column after column of 16 bytes, 8 a row |
