# Music: the 128K's AY tunes and effects

`music.txt` holds every resource of the music part but the period table (src/music, RAM 1 `$C000`; the game image's
`$5E00-$6BA3` before CopyMusicToRam1 `$A069` copies it). `tools/res_music.py` (a format module of
`tools/res_formats.py`) turns it into the seven `.bin` files the sources INCBIN and back; `tools/res_formats.py check`
proves the round trip.

| Resource | Address | Entry | What | In the text |
| --- | --- | --- | --- | --- |
| `music/periods.bin` | `$C000-$C0A9` | PeriodTable | the 85 tone periods from C-1, with the original's two typos (index 20, 24) | `periods.txt`: `INDEX NOTE PERIOD` lines (`tools/res_tables.py`) |
| `music/patterns.bin` | `$C6E5-$CA8E` | Patterns | the 55 patterns | `pattern N` blocks |
| `music/tunetable.bin` | `$CA8F-$CABE` | TuneTable | 8 tunes x 3 order list addresses | `tune N:` lines (names, the addresses come from the layout) |
| `music/orders.bin` | `$CABF-$CC49` | OrderLists | the 24 order lists | `order NAME:` lines, in stored order |
| `music/patternlo.bin`, `patternhi.bin` | `$CC4A-$CCB7` | PatternLo, PatternHi | the patterns' addresses, low and high bytes | made from the layout |
| `music/instruments.bin` | `$CCB8-$CD07` | Instruments | 8 instruments of 10 bytes | `instrument N:` lines |
| `music/effects.bin` | `$CD08-$CDA3` | EffectTable | 12 effects of 13 bytes | `effect N:` lines |

Readers: PlayTune `$C3E4` (TuneTable), TrackStep `$C4B4` (order lists, patterns, PatternLo / PatternHi),
PatternCommand `$C5BB` and PlayTune (Instruments), PlayEffect `$C685` (EffectTable). Nothing writes them.

## The format

**Instruments** (10 bytes): attack step, decay step (signed), sustain level, release step (signed), peak volume, vibrato
delay (frames, 255 none), vibrato length (0: a slide that goes on, bit 7: a slide that stops, else half a vibrato
period), the step added to the period offset a frame (a word; the AY keeps 12 bits of the period, so `$0FF8` is -8),
flags (bit 0 tone, bit 1 noise, bit 2 a fixed volume). The volume runs 0-255 and the AY gets it / 8; the envelope is
software: attack up to the peak, decay down to the sustain, hold until the note's frames end, release to 0.

**Effects** (13 bytes): an instrument, then the period (word) and the note's frames. PlayEffect starts it on the
next channel in turn (effect 4: always B) and holds the channel until its release ends.

**Tunes**: three order lists, channels A, B, C. **An order list**: `P n` (byte n < `$80`) plays pattern n; `xN`
(`$80`+N) plays the next pattern N times (the player reads bits 0-4); `t+N` (`$FE` N) transposes the next patterns by
N semitones; `mapK=V` (`$C0`+K V) sets instrument slot K & 7 of the track (no tune uses it); `end` (`$FF`) stops
the channel.

**A pattern**, one line a step:
- `NOTE FRAMES` (NOTE FRAMES, NOTE < `$7E`): the note sounds at the period table's index note + transpose + 12, so
  the name is of the untransposed note, C-1 being the table's first entry. The table is an Atari ST one (2 MHz): on the
  Spectrum's 1.7734 MHz AY every note sounds about two semitones lower than its name. FRAMES at 50 a second;
- `rest FRAMES` (`$7F` FRAMES);
- `period $XXXX FRAMES` (`$7E` LO HI FRAMES): a period given directly (no tune uses it);
- `instrument N` (`$80`+N): instrument slot N for the next notes;
- `cmd $XX ...`: `$88`-`$BF` an ornament (the player's ornament table was not kept: it would read code), `$C0`-`$FE`
  skipped (`$C2` one byte, the others four). No tune uses them;
- the pattern's end byte `$FF` is written by the build.

Editing: the text may grow or shrink patterns and lists; the build lays them out again and makes the address tables.
The INCBINs take the sizes of the original, so a change of size needs the source's entries moved too.

## What plays where

| Tune | Game call | Recordings |
| --- | --- | --- |
| 0 | `$E324`, a level's intro (LevelIntro) | `controls`, `gameover`, `level1` |
| 1-4 | `$AC20`, a level's end (the number from `$E4AD`) | 4 in `ending` (stage 1) and `ending2` (stage 2); 1-3 in none |
| 5 | `$E220`, the menu | `controls`, `gameover`, `level1`, `ending` |
| 6 | `$E386` (GAME OVER) | `controls`, `gameover`, `level1`, `ending` |
| 7 | `$F531`, the bonus end marker | `level1` |

The effects: 0 a shot, 1 fire with no bullets, 2 the dynamite's bang, 3 a trap set off or a poke, 4 Rick's steps, 6 a head against a ceiling, 8 ammunition picked up, 9 a treasure, 10 the bonus count's start, 11 Rick's death or an enemy hit; call sites in src/music/music.ann (EffectTable). Effects 5 and 7 have no call site; effect 8
(`$ED76`) ran once, in the zone recording L1Z4 (work/stage2/zones, Rick takes the bullet box). The 48K plays its effects on the beeper (`$A08E`) and has no music.
