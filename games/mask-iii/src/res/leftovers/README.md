# Leftovers

Bytes in the loaded image that no routine reads before writing them (known only from the code, src/game/game.ann).

| File | Entry | What |
| --- | --- | --- |
| `zone1-attrs-old.bin` | Zone1AttrsLeftover `$6300` | an older copy of zone 1's attributes; GameEntry copies `$EE00` over it (255 of 256 bytes equal) |
| `e800.bin` | SpriteChars `$E800` | 1536 bytes where DrawObject builds the sprite characters |
| `f500.bin` | LeftoverF500 `$F500` | 256 bytes of the dirty map's place |
| `fc00.bin` | LeftoverFC00 `$FC00` | 100 bytes between the panel and its attributes |
| `fd24.bin` | LeftoverFD24 `$FD24` | 220 bytes under BuildTables' shift tables |

The 35 zero bytes PassBcdSpare `$CC5D` and the 128 of DissolveBuffer `$DF80` are `DEFS` in the source.
