# Music

## The intro tune

| File | Address | Size | Format | Read by |
| --- | --- | --- | --- | --- |
| `sk10.txt` | `$8990`-`$90C4` | 1845 bytes | the STarKos song `SK10` as text (`tools/sk10.py`, the format in its docstring) | the STarKos player at `$8000` (`src/sound/starkos.asm`): `Init` reads the header, `Play` the streams, tracks and instruments |

`tools/build_sound.sh` encodes it into `build/sound/sk10.bin`, which `src/sound/starkos-song.asm` includes with
`INCBIN`; `python3 tools/sk10.py check src/res/music/sk10.txt work/parts/starkos-8000.bin` proves the round trip.
`python3 tools/sk10.py rows src/res/music/sk10.txt` prints the patterns as a time grid.

The song is only read: the player keeps all its state in the operands of its own instructions (`src/sound/starkos.ann`,
named there). The song's bytes in the recording at frame 2600, after 385 frames of play
(`work/images/intro-title-bank2.bin`), equal the loaded ones.

The file in brief:

- A header: the song's address (`song $8990`: the player does not relocate it), the drum channel, the rate, the
  speed (`speed 5`: six frames a line) and the four loop points.
- `[transpositions]`, `[heights]`, `[speciallist]`: the three run-length streams the player reads once a pattern.
- `[linker]`: three tracks a pattern, 48 patterns.
- `[instruments]` and `[instrument iK]`: 13 instruments, a header (speed, loop, retrigger) and one line a frame step
  (`soft`, `mute`, `noise`, `fixed`, `hard`).
- `[track tNN]`: 38 tracks. `[special sNN]`: one special track (the speed).

Note names are scientific pitch at the CPC's 1 MHz AY clock (STarKos note 12, period 3822, is C0). On the ZX
128K's 1.7734 MHz the same periods sound 9.92 semitones higher (docs/09-sound.md 9.6).

## The title tune of the game

The game's title tune (the credits page) as text, the 48K's bytes and format (`../zynaps`). On a 128K the 2 in 1
silences it (docs/09-sound.md); on a 48K it plays. `tools/res_tune.py` turns `titletune.tune.txt` into the bytes the source INCBINs
(`music/titletune.bin`, `$FF01-$FFD3`, 211 bytes) and back; `tools/res_formats.py check` proves both ways, and
`python3 tools/res_tune.py check FILE.bin` does it for one file of bytes.

| File | Address | Size | Format | Reader |
| --- | --- | --- | --- | --- |
| `titletune.tune.txt` | `$FF01-$FFD3` | 211 | 27 periods, 7 pattern pointers, 4 patterns (below) | TitleTune `$B446`, from CreditsPage `$B095` |

### The format

```
periods 0 242 231 ...     TunePeriods $FF01: the period of note n, in passes of the tone loop
order A A B A C C D       TuneOrder $FF1C: the patterns in play order (7 pointers)
pattern A                 a pattern: L<n> sets the note length, a number plays that note
  L1 7 6
  L2 4
end                       the pattern's $FF
```

The patterns are laid out in the text's order right after the order table, so a pattern may grow or shrink; the
code reads exactly 27 periods and 7 order entries. Lines from `#` on are comments; the header and the table of note
frequencies are written again on every install.

### How the player sounds it

TitleTune (`$B446`) runs with the interrupts off. A length command `$C0+n` (`L<n>`) sets the note to n x 16 x 256
passes of the tone loop (`$B486-$B49B`, 81 T a pass, so `L1` is 0.095 s on a 48K). A note byte n takes p =
TunePeriods[n] and runs two counters, p and p + 1 passes; each counter's wrap flips the speaker bit (both at once flip
it once). So a note is two square waves a pass apart, about 3500000 / (2 x 81 x p) Hz, with a slow beat between them:
note 1 (p = 242) is about 89 Hz, note 26 (p = 54) about 400 Hz; the periods fall by about a semitone a step. Between
notes the player checks fire (TitleFireCheck `$A748`) and the keys 1-5; either ends the tune.

The four patterns: A (three times) the theme, B the climbing arpeggios, C (twice) an ostinato of 16 quavers, D the
closing phrase. Notes 3, 15, 22, 24 and 26 are never played (a c1 recording reads only the other periods).
