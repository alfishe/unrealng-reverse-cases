# Tune

The tune as text, one word a line: the ROM BEEPER's period + 1 (BEEPER `$03B5`), `rest` for 0, `loop` for `$FFFF` (back
to the start). TunePlayer `$7F47` takes the next word every third interrupt (TuneDivider `$B240`, pointer `$B23E`) unless the tune is
off (PlayerFlags `$B288` bit 7, the T key `$AF15`: a rest then, the tune keeps its place).

| File | Address | Bytes | Format | Readers | What |
| --- | --- | ---: | --- | --- | --- |
| `Tune.txt` | `$B4E6-$B7E7` | 770 | text, one word a line | LifeStart, TunePlayer | The tune played through the game: 384 words, one note every 3 interrupts, `$FFFF` ends it |
