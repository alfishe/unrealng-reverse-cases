# The intro tune

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
