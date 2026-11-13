# Leftovers

Bytes no routine reads (no recording reads them either, unless said), kept as they are.

| File | Address | Bytes | What |
| --- | --- | ---: | --- |
| `unused-61a8.bin` | UnusedPicture61A8 `$61A8` | 496 | CPC picture data of the original |
| `unused-75a8.bin` | UnusedPicture75A8 `$75A8` | 480 | CPC picture data |
| `unused-8385.bin` | Unused8385 `$8385` | 2231 | CPC picture data |
| `e0c4.bin` | LevelLeftover `$E0C4` | 85 | unknown |
| `sfx-*-params.bin` | after each effect's `LD HL` (`$F3CF`, `$F3E6`, ... `$F500`) | 16 each | parameter blocks of the effects, never read as such (RomNoise uses only the low byte of `$F3E6`) |
