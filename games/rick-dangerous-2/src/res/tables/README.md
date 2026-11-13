# Tables

| File | Address | Bytes | What | Format | Read by |
| --- | --- | --- | --- | --- | --- |
| `beeper-effects.txt` | `$7B08` | 94 | the eleven 48K beeper effects: each note's half period in loop turns, `$FF` ends an effect | one effect a line, decimal bytes (the `$FF` is the line end); BeeperEffectTable `$7AF2` holds each line's address | PlayBeeperStep `$7B66` (48K only) |
| `level-starts.csv` | `$7C8F` | 30 | Rick's start in each level | level, section, view row, x, y (a word), the mirror byte | LevelSetup `$7CF2` |
| `points.csv` | `$7EF3`-`$7F16` | 6 x 6 | the score constants 50, 100 (unused), 500, 5000, 10 000, 100 000 | name, six digits (one byte each, 0-9) | AddScore `$7ED3` callers |
| `section-counts.csv` | `$8374` | 5 | the sections of each level: 9, 13, 10, 13, 8 | level, sections | ResetSectionObjects |
| `explosion-frames.csv` | `$93C0` | 10 | the blast's sprites by fuse step | frame, sprite (the word = `$C26D` + 128 x sprite) | BurnFuse |
| `rick-walk-frames.csv` | `$9AA9` | 14 | Rick's walk (5) and crawl (2) sprites | frame, sprite | PickRickSprite |
| `periods.csv` | RAM 1 `$C672` | 170 | the AY tone periods of 85 semitones from A#0 | index, period, note name | SetPitch `$CCB5` (src/music) |
