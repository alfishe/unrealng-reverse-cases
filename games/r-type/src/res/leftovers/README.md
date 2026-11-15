# Leftovers

Bytes the game never reads: what the loader and older builds left. Each file's entry says how it is known (the heatmap of every recording, or the code alone).

Format: bytes.

| File | Entry | Address | Bytes | What |
| --- | --- | --- | --- | --- |
| `hiscore-spare.bin` (bytes) | HiScoreSpare (`src/game/game.ann`) | `$7D71` | 17 | the 17 bytes past the ninth entry the insertion shifts the last entry into (no recording reads them) |
| `graphics-head.bin` (bytes) | GraphicsHead (`src/game/game.ann`) | `$A5F7` | 13 | bytes before the first sprite (no recording reads them; known only from the heatmap) |
| `loader-leftover.bin` (bytes) | LoaderLeftover (`src/game/game.ann`) | `$C544` | 6100 | bytes the loader's last moves left, never read before a level overwrites them |
| `level-space-tail.bin` (bytes) | LevelSpaceTail (`src/game/game.ann`) | `$F818` | 100 | the bytes after the picture |
| `stack-area.bin` (bytes) | StackArea (`src/game/game.ann`) | `$FF94` | 108 | Loader leftovers (never read) and the stack (SP = $FFFE) |
