# Music

Bank 4's AY player data (128K only, `src/bank4/bank4.ann`; work/stage2/ann/BANK4.md sections 3.1-3.3): three tunes by
Ben Daglish and the 128K sound effects.

| File | Address | Bytes | Format | Readers | What |
| --- | --- | ---: | --- | --- | --- |
| `tunes.txt` | Patterns `$C4B8`, PatternAddrLo `$CC97`, PatternAddrHi `$CCC4`, TuneTable `$CCF1`, OrderLists `$CD03` (to `$CE8B`) | 2516 | text, below | ReadOrderList `$C1E9` (StartTune through TuneTable, OrderPattern through PatternAddrLo/Hi), ReadPatternCommand `$C31F`, ReadEvent `$C27E` | the 45 patterns and the 9 order lists (3 tunes x channels A, B, C); the pointer tables are computed |
| `arpeggios.csv` | Arpeggios `$CE8C-$CED3` | 72 | CSV, 8 bytes a record | ArpeggioStart, UpdateArpeggio `$C390` | arpeggios 1-9: a head (bit 7 loop, bits 3-5 the note's own frames, bits 0-2 + 1 the steps) and the steps (bits 3-7 semitones, bits 0-2 frames) |
| `instruments.csv` | Instruments `$CED4-$CF5F` | 140 | CSV, 10 bytes a record | ReadPatternCommand `$C31F` (through the slots), StartNote `$D0DA` | 14 instruments: the envelope steps, sustain, peak, the vibrato, the mixer flags |
| `effects.csv` | Effects `$CF60-$D015` | 182 | CSV, 13 bytes a record | PlayEffect `$C011` | the 14 sound effects on channel A: an instrument, the tone period, the gate time |
| `notes.csv` | NoteTable `$D016-$D09B` | 134 | CSV, 67 words | ReadEvent `$C27E` (EventNoteIndex, SetNotePeriod), AyUpdate `$D1C3` | the tone periods; `_note` is the note name (index n = MIDI 40 + n on channels B and C, an octave lower on A) |

## tunes.txt

- `pattern NN ; $ADDR`, followed by one line of events (`-` for an empty pattern):
  - `NOTE:frames`: a note; index n is named as MIDI note 40 + n (E2 = 0);
  - `r:frames`: a rest;
  - `per$XXXX:frames`: a raw tone period;
  - `iN`: instrument slot N;
  - `arpN`: arpeggio N;
  - `port(a,b,c)`: a slide, after a frames, over b frames, by c semitones;
  - `portoff`;
  - `drum(len,noise)` and `drumoff`;
  - `$XX`: a byte the player skips.
- `order T C ; $ADDR`, followed by one line of events for tune T, channel C:
  - `Pnn`: a pattern;
  - `xN`: play the next pattern N times;
  - `trN`: the transpose in semitones, which stays until changed;
  - `slotS=insI`: put instrument I into slot S;
  - `fd(a,b)`: ignored by the player;
  - `$XX`: any other byte.

Each line ends with the `$FF` end mark. The patterns are written in address order, from `$C4B8`, and the order lists
follow the tune table. PatternAddrLo, PatternAddrHi and TuneTable are recomputed from the sizes. The whole file must
keep its size (2516 bytes).

The tunes are: 0 the title, 1 the in-game music, 2 the start jingle. Patterns 42-44 are empty (one `$FF` each).
