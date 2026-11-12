# Music

The tune of the music piece (`src/music`, loaded by TR-DOS to `$C000-$D5FF`): one module of ASC Sound Master, the AY
tracker by Andrew Sendetski (ASC), played by the compiled player at `$C000` (module player of `src/music/music.ann`).
The player's text names the tune "DISCO MUSIC BY ANT P". The player's own data (the period table, the channel records,
the AY register image) stays in the source; the 109 bytes after the module (SectorTail `$D593`) are sector filler,
not music.

| File | Address | Bytes | Readers | What |
| --- | --- | ---: | --- | --- |
| `disco.txt` | TuneHeader `$C478` - OrnamentData (to `$D592`) | 4379 | InitPlayer `$C053` (the header), NextPosition `$C191` (positions, pattern table), ChannelRow `$C1CE` and PatternCommand `$C24C` (streams), TableEntry `$C278` (sample and ornament tables), SampleStep `$C308`, OrnamentStep `$C385` | the whole module: delay, positions, 16 patterns of 3 streams, 32 samples, 32 ornaments |

`tools/res_music.py` converts it (`to_editable` / `from_editable`, called by `tools/res_formats.py` for names under
`music/`); `python3 tools/res_formats.py check` proves the text gives the bytes back, and
`python3 tools/res_music.py dump` prints the text of the image's module.

## The module (ASC Sound Master 0.x layout)

| Offset | Bytes | What |
| --- | ---: | --- |
| `+0` | 1 | the delay: frames a row (6) |
| `+1` | 2 | the pattern table, an offset from the module |
| `+3` | 2 | the sample table, an offset from the module |
| `+5` | 2 | the ornament table, an offset from the module |
| `+7` | 1 | the number of positions (22) |
| `+8` | n | the positions: a pattern number each. There is no loop byte: after the last position the tune starts again at position 0 |
| table | 6 a pattern | the offsets (from the table) of the streams of channels A, B and C |
| table | 2 x 32 | the samples' offsets (from the table) |
| table | 2 x 32 | the ornaments' offsets (from the table) |

The tables are followed by the streams, then the samples, then the ornaments, in that order in this module.

## disco.txt

Lines starting with `#` are comments. The blocks come in the order of the bytes; the converter rebuilds the header's
offsets and the three tables from the blocks, so a stream, a sample or an ornament may grow or shrink, and patterns,
samples and ornaments may be added at the end of their kind (the player takes sample and ornament numbers 0-31 and,
through an 8-bit product, patterns 0-42).

- `delay N`: frames a row.
- `positions P0 P1 ...`: the pattern of each position.
- `pattern N`, then `A`, `B`, `C` (indented), each followed by its stream (indented more), one line a row event with the
  commands before it on the same line. The three streams of a pattern must last the same number of rows: the next
  position starts when all three have met their `end`.

| Token | Byte | Does |
| --- | --- | --- |
| `C-4`, `F#2`, ... | `$00-$55` | a note: the sample and the ornament restart. Note 0 is `A#0`, note 2 `C-1` (MIDI = note + 22 at the 128K's AY clock of 1.7734 MHz); the top note `$55` is `B-7` |
| `---` | `$56` | no new note: the current one goes on for the row length; `---$NN` keeps another byte `$57-$7D` (the same effect) |
| `rel` | `$7E` | release: a sample's loop no longer loops, so it runs on to its end |
| `off` | `$7F` | silence the channel |
| `sN` | `$80+N` | sample N (0-31) |
| `oN` | `$A0+N` | ornament N (0-31) |
| `env` | `$C0` | envelope mode: each following note is followed by `ep$NN`, the envelope period (AY register 11), and a sample row with `E` plays on the AY envelope |
| `vN` | `$C0+N` | the channel volume 1-15 (scales the samples' volumes); ends envelope mode |
| `nN` | `$D0+N` | the noise base 0-31 (the noise period a note starts with) |
| `lenN` | `$F0 N` | the row length: rows each following event lasts |
| `shapeN` | `$F0+N` | the AY envelope shape 1-15 (register 13, written at once: it restarts the envelope) |
| `ep$NN` | `NN` | the envelope period byte after a note in envelope mode |
| `byte $NN` | `NN` | a byte that starts no event (none in this module) |
| `end` | `$FF` | the end of the stream |

- `sample N`, then one row a line (a row a frame): `FLAGS noise N tone T vol V MIX`.
  - FLAGS, three letters or `-`: `S` this row is the loop row; `L` after this row go back to the loop row (unless the
    note was released with `rel`); `X` the sample ends after this row (silence; only checked when the row does not
    loop back).
  - `noise N`: added to the channel's noise period (-16 to 15).
  - `tone T`: added to the channel's tone period offset (-128 to 127); the offsets add up from the note's start.
  - `vol V`: 0-15, played as V x (channel volume + 1) / 16.
  - MIX, four letters or `-`: `T` tone on, `N` noise on (and the noise period sent to the AY), `E` the envelope (in
    envelope mode), `4` the unused bit 2 of the byte.
- `ornament N`, then one row a line (a row a frame): `FLAGS noise N note D`: FLAGS as for samples (`L` always loops;
  `X` has no effect for an ornament), `noise N` as for samples, `note D` added to the channel's note (the deltas add up
  from the note's start: `+12`, `-12` alternates the note and its octave).

## Editing

Edit `disco.txt`, then `python3 tools/res_formats.py check` (the text must parse) and rebuild the part
(`python3 ../../kit/mkgame.py --part src/music/music.json`). An edited module no longer matches the original bytes,
so the part's comparison will report the first difference; the labels inside the module in `src/music/music.ann`
(Pattern1, Sample1, ...) are the original addresses and need moving if their blocks move.
