# Tunes and effects (the RAM 1 music, src/music)

Copied to RAM 1 at `$C000` by CopyMusic `$7BBF` on a 128K; a 48K has no music (tables/beeper-effects.txt instead).
The player runs once a frame (MusicFrame `$CAAF` from the IM 2 handler), so every duration counts 50ths of a second.

| File | Bytes (RAM 1) | What | Format |
| --- | --- | --- | --- |
| `patterns.txt` | `patterns.bin` `$C000` 704, `pattern-low.bin` `$C444` 54, `pattern-high.bin` `$C47A` 54 | the 54 patterns and their address table | a line per `$FF`-ended stream; `[Pnn]` where pattern nn starts (patterns share tails); `NOTE:frames` a note (MIDI names, C4 = 60; byte = MIDI - 34), `r:frames` a rest, `perP:frames` a note by tone period, `iK` instrument K (`$80`+K), `oK` ornament K (`$90`+K), `{XX}` a byte as it is |
| `tunes.txt` | `tune-table.bin` `$C2C0` 66, `order-lists.bin` `$C302` 322 | the 11 tunes: three order lists each (AY channels A, B, C) | a line per `$FF`-ended list; `[TnnA]` where tune nn's channel A list starts; `Pnn` a pattern, `xN` the next pattern N times, `t+N` transpose; an empty line is a list with only its `$FF` |
| `instruments.csv` | `$C4C0` 70 | instruments 0-6 | attack, decay, sustain, release, peak (volume 0-127), sweep delay, sweep frames, sweep step (signed period units a frame), flags (bit 0 tone, 1 noise, 2 AY envelope, 7 notes keep the voice) |
| `effects.csv` | `$C506` 364 | the 28 sound effects | an instrument's fields, then the tone period and the sustain frames (`$FF` until replaced) |
| `ornaments.csv` | `$C4B0` 16 | ornaments 1 and 2 | loop, the base step's frames, the steps used, then 7 steps semitones:frames |

The tunes (MusicStartTune `$CA27`, A = the tune): 0 the control menu and the CONGRATULATIONS end, 1 a signal (the
time bonus, both cheats), 2 GAME OVER, 3 never started, 4 the tape load (silence), 5-9 levels 1-5 (Level + 4), 10 the
Fat Guy's end. The effects (MusicEffect `$CCC8`): 0 a step, 2 the fuse, 4 a shot, 5 a blast, 6 ammunition or
detonators taken, 7 a treasure, 9 an enemy punched, 10 a death and each life counted at the end; the traps' paths and
scripts ask for theirs from the level data. Read by SequenceChannel `$CAF7`, PatternCommand `$CBFE`, StartVoice `$C754`,
UpdateOrnament `$CC80`, MusicEffect `$CCC8`.
