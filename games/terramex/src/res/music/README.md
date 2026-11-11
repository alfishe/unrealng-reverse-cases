# Music

The tunes and tables of Ben Daglish's AY player (src/music, TZX block 4 `$6000-$71FF`, run in RAM 6 at `$C000`; the
addresses below are the RAM 6 ones). The player plays only tune 0 (StartTune `$C79F` is reached only with A = 0) at
every interrupt on a 128K; a 48K has no music. The beeper sound effects are game code (SoundEffects `$C55B`, module
sound), not data here. The full format is in the `@about` lines of src/music/music.ann (modules channel, effects,
tunes).

| File | Address | Bytes | Readers | What |
| --- | --- | ---: | --- | --- |
| `tunes.txt` | TuneTable `$C967` - Pattern26 `$CD33` (to `$CD35`) | 975 | StartTune `$C79F`, StartPattern `$C34A`, the order-list and pattern readers of module channel | the 4 tune entries, the order lists of tunes 0 and 1, the 27 patterns |
| `instruments.csv` | Instruments `$C028` | 243 | SlotRowOp `$C3DA`, the envelope set-up | 27 records of 9 bytes (0-10 real, 11-26 blank) |
| `slots.csv` | SlotTable `$C11B` | 48 | SlotIndexOp, SlotRowOp | per channel 8 slots: the record offset (9 x record) the instrument command `$8n` takes |
| `vibratos.csv` | VibratoTable `$C906` | 8 | StartNote `$C4C9`, VibratoStep `$C626` | the one vibrato record (offset 8): a delay, 7 signed period deltas |
| `arpeggios.csv` | ArpeggioTable `$C927` | 64 | ArpeggioApply `$C6C2`, StartNote | 8 arpeggio records of 8 bytes |
| `envelope-rates.txt` | AttackRates `$CD36`, DecayRates `$CD46` | 16 + 16 | SetInstrumentEnvelope `$C42D`, SetInstrumentRelease `$C48E`, the sustain set-up | the ADSR rate by nibble: below `$80` steps a frame, `$80 + n` one step every n frames |
| `periods.csv` | PeriodLo `$C82E`, PeriodHi `$C89A` | 108 + 108 | StartNote `$C4C9`, ArpeggioEffect and the slide (module effects) | the AY tone period of each note index 0-107 (MIDI i + 12, C0 to B8), one row a note: index, the note name (not read back), the period |

## tunes.txt

The blocks in address order, each `block NAME` then its events; the pointers of TuneTable and PatternLo/PatternHi are
written back from the block layout, so a block may grow or shrink.

- `tune N A B C`: the order lists of channels A, B and C (tunes 2 and 3 repeat tune 0's).
- Order lists: `pattern N`, `transpose T` (signed semitones for the patterns after it), `repeat N` (the next pattern N
  times), `detune D`, `slot N R` (SlotTable[8 x channel + N] = R), `end`.
- Patterns: `note N D` (a note of D frames; the comment after `;` names it at transpose 0: note n is MIDI n + 32,
  note 0 = G#1 at the 128K's AY clock of 1.7734 MHz), `rest D`, `instr N`, `arp $XX`, `slideoff`,
  `slide $CMD STEP COUNT`, `end`; `byte $XX` keeps a byte that starts no event.

Tune 0 has 9696 frames of notes and loops every 9698 frames (3 min 14 s: the notes, the EndTune
frame and the StartTune frame); tune 1 (4728 frames on A and B) is never started. Patterns 4 and
21-25 are played by no tune.
