# Sound

The beeper sound data: `sound-data.bin` the note periods (54 words from `$FB66`), the channel slots, the command table at `$FBEB` and the script table at `$FC0B` (40 sounds); `sound-scripts.bin` the scripts SoundStep `$F913` reads.

Format: bytes.

| File | Entry | Address | Bytes | What |
| --- | --- | --- | --- | --- |
| `sound-data.bin` (bytes) | SoundData (`src/game/game.ann`) | `$FB66` | 310 | The sound data: note periods, the channel slots, the command table ($FBEB), the script table ($FC0B) |
| `sound-scripts.bin` (bytes) | SoundScripts (`src/game/game.ann`) | `$FC9C` | 259 | the sound scripts |
