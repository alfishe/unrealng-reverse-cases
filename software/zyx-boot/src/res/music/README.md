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
`python3 tools/res_music.py dump` prints the text of the image's module. The build also writes `music/disco.inc`
(`to_inc`): the module as DB lines with the labels of `src/music/music.ann` (TunePositions, PatternTable, Pattern1,
SampleTable, Sample1, ...) at their blocks. The tune's eight entries share it (`@res music/disco.bin include` on each,
one INCLUDE at TuneHeader), so a tune of another size or shape moves the labels with its blocks; what then has to
give is SectorTail, the filler up to the 22nd sector (`music.bin` stays 5632 bytes).

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
  commands before it on the same line. The three streams of a pattern should last the same number of rows. The
  next position starts on the first row frame after all three have read their last event (the byte after it is `end`),
  even if that event still runs; a channel then reads the new pattern only when its last event's rows are over.

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

# The variants' music

A variant's music piece (variants/NAME/music) is kept readable when its player is one of the three shared players in
`variants/players` (kit/mkgame.py pieces, one source for every variant that has the player); else it stays
`music/piece.bin` (work/docs/zbV-music.md lists every variant, its player, its tune and why). `tools/variants.py`
builds the piece through `tools/variants_music.py`: the player assembled at the variant's `MusicPiece`, the variant's
own bytes laid over it, the tune converted from its text, then the tail. `python3 tools/variants_music.py convert NAME`
writes the readable form from the piece and keeps it only when the variant still builds identical;
`python3 tools/res_formats.py check` proves every variant's text gives its bytes back.

| Player | Variants | Player source | Tune file | Converter |
| --- | --- | --- | --- | --- |
| Sound Tracker (compiled) | zyxalex2, zyxarbt, zyxdebt, zyxfzbt, zyxhsbt, zyxkombt, zyxlebt, zyxlesbt, zyxlogrb, zyxm94bt, zyxrusbt, zyxskitb | `variants/players/stc` (at the variant's base, the module at +`$43C`) | `stc.txt` | `tools/res_stc.py` |
| ASC Sound Master, later compilation | zyxboot-14 to zyxboot-18 | `variants/players/asc2` (`$C000`, the module at `$C4A7`) | `asc.txt` | `tools/res_music.py` |
| Fuxoft (Frantisek Fuka) | zyxae, zyxamebt, zyxboot-02, -03, -04, -06, -07, -09, -13, zyxgambt, zyxisl, zyxkisbt, zyxmegbt, zyxmixmb, zyxsdbot, zyxsdgrp, zyxslbt, zyxtribt, zyxzxtbt | `variants/players/fuxoft` (`$EB50`, the tune at `$F035`) | `fuxoft.txt` | `tools/res_fuxoft.py` |

## player.txt

- `player KIND`: `stc`, `asc2` or `fuxoft` (the folder in `variants/players`).
- `tune FILE`: the tune's text in the same folder.
- `at LABEL+N HEX...`: bytes that differ from the player's source: what the player's variables, stacks and
  self-modified operands held when the disk was saved, the ASC player's text (the tune's title and author) and its
  header bytes, the Fuxoft player's noise mask. LABEL is a label of the player's source, or a self-modified operand
  `tools/variants_music.py` names (`ModuleBase`, `OrnamentRow`, `Transposition` in the STC player, `NoiseMask` in
  Fuxoft's); N counts bytes from it.
- `at +N HEX...`: the same, N an offset from the piece's start. It names no label, so the line keeps working when the
  shared player's labels are renamed; zyxremix uses it (its piece borrows zyxboot-11's player, which another session
  may edit). An `at` line naming a label the player no longer has stops the build with the label's name.
- `tail`, then indented hex lines: the bytes after the tune to the end of the piece's last sector (sector filler).

## asc.txt

As `disco.txt`, with `commands v2` after the comment: the later compilation's player reads other command bytes. Notes
`$00-$55`, `ep$NN` and `end` are as above; the rest:

| Token | Byte | Does |
| --- | --- | --- |
| `---` | `$56` | no new note (`---$NN` keeps `$57-$5D`) |
| `rel` | `$5E` | release |
| `off` | `$5F` | silence the channel |
| `lenN` | `$60+N` | the row length 0-63 |
| `sN` | `$A0+N` | sample N |
| `oN` | `$C0+N` | ornament N |
| `env` | `$E0` | envelope mode (each note is followed by `ep$NN`) |
| `vN` | `$E0+N` | the channel volume 1-15; ends envelope mode |
| `noiseN` | `$F0 N` | the noise base |
| `shapeN` | `$F0+N` | the envelope shape 1-15 |

Sample rows keep the letters of `disco.txt`; this player reads the third byte's bits 1-2 as a whole: `E` alone (2) is
the envelope, `4` alone (4) the volume -1 a row, `E4` (6) the volume +1 a row.

## stc.txt (Sound Tracker module)

The module the compiled player reads: `+0` the delay, `+1`, `+3`, `+5` the offsets of the positions, the ornaments
and the pattern table, `+7` the identifier `SONG BY ST COMPILE`, `+25` the module's size, `+27` the samples (99
bytes each), then the positions, the ornaments (33 bytes each), the pattern table (7 bytes each, `$FF` after the
last) and the streams. The text keeps the blocks in the order of the bytes and rebuilds the offsets from it.

- `delay N`, `id TEXT` (`{XX}` for a byte that is not plain text), `size N` (written as it is).
- `sample N loop P L`, then 32 rows `vol V noise N tone ±$DDD TN`: the volume, the noise (0-31), the tone offset (sign
  and 12 bits), `T` tone on, `N` noise on (`-` off). `loop P L`: the loop row and its length.
- `positions P:T ...`: the pattern and the transposition of each position.
- `ornament N D1 ... D32`: the note offsets.
- `pattern N sA sB sC`: the pattern's three streams by their numbers; `patterns end` writes the table's `$FF`.
- `stream K`, then the events (indented): a note `C-1` (note 0) to `B-8`, `sN` sample, `oN` ornament, `rest` (`$80`),
  `---` empty (`$81`), `noenv` (`$82`: ornament 0, envelope off), `envN,$PP` (`$80+N` with N 3-14 and the envelope
  period), `lenN` (`$A1+N`, the row length), `end` (`$FF`), `$XX` any other byte.
- `bytes HEX...`: bytes no block covers, where they lie.

## fuxoft.txt (Fuxoft's player)

The player reads its tune at fixed addresses: three words at `$F035` (the start of the streams of channels A, B and
C), then whatever they point to. The text names every address a word points to: a label line `NAME: KIND` (KIND
`stream`, `instrument`, `ornament` or `bytes`) starts a block, `: KIND` switches the kind without a label; text ->
bytes assembles the blocks in order and resolves the labels, so a block may grow or shrink.

- `org $F035`, `channels A B C`: the labels of the three streams.
- A stream: `NOTE/D` a note and its frames (`A-0` is note byte 1; `r/D` silence), `goto:L` (`$80`), `call:L` (`$81`,
  a sub-stream ending with `ret`), `repeat:N` ... `next` (`$82 N` ... `$83`), `noise:N` (`$84`, the noise period),
  `mixer:N` (`$85`, the channel's mixer bits: 8 tone only, 0 tone and noise), `orn:L` (`$86`), `instr:L` (`$87`),
  `transp:N` (`$88`), `ret` (`$89`), `tie` / `untie` (`$8A` / `$8B`: a note keeps the volume stream running),
  `code:L` (`$8C`, a machine code routine), `noise+:N` (`$8D`, masked by the player's noise mask), `transp+:N`
  (`$8E`), `$XX` another byte.
- An instrument: `V/D` a volume and its frames (the first item always has this form; a byte below `$1E`), `V` a
  volume for one frame (the byte `V + $32`), `goto:L`.
- An ornament, one item a frame: `notes` (`$82`: the items add notes to the note), `steps` (`$83`: the items add to the
  tone period), `noisemix` (`$84`: toggle the channel's tone and noise, its mixer bits XOR 9), a signed number, `goto:L`.
- `bytes`: hex bytes no walk reaches (an unused instrument, a code routine).

## The one-off players' tunes

The game-rip players read their tunes at addresses fixed in their code, so their tunes stay where the code reads
them; the text keeps every byte in its order and names what the code points to. Each player is a shared `.ann`
part in `variants/players/KIND` (named and described; `kit/mkgame.py` assembles it identical); its tune is text in
the variant's `music/` (`tools/variants_music.py convert NAME` splits a piece, `build_piece` puts it back):

| Text | Converter | Players (variants) |
| --- | --- | --- |
| `whittaker.txt` | `tools/res_whittaker.py` (`version platoon`, `dizzy` or `storm`) | David Whittaker's driver: Platoon (zyxboot-05, -08), Fantasy World Dizzy (zyxboot-10, zyxsiriu), Stormbringer (zyxboot-11, zyxremix) |
| `sheridan.txt` | `tools/res_sheridan.py` | Ian Sheridan's Subway Vigilante (zyxboot-12) |
| `daglish.txt` | `tools/res_daglish.py` | Ben Daglish's Pac-Mania (zyxrover) |
| `hydrofool.txt`, `megaapoc.txt`, `ziutek.txt`, `awbt.txt`, `fp3bt.txt` | `tools/res_rip.py` (`format KIND`) | Hydrofool (zyxalex), Mega Apocalypse (zyxdimob), Ziutek's Part V (zyxfp4bt), Altered Beast (zyxawbt), Marauder (zyxfp3bt) |
| `asc1.txt` | `tools/res_music.py` (`layout asc1`, `commands asc1`) | ASC Sound Master 1.x module layout (zyxboot-01) |

- `whittaker.txt`: `version`, `org` (the song table), then the songs (tempo and three order lists), the order lists
  (pattern words, ending with 0) and the patterns: note names, the version's named commands with their argument
  bytes, durations, instruments, ornaments, `end` / `stop`.
- `res_rip.py` texts: `format KIND`, `org $XXXX`, then labelled blocks in address order (`NAME: KIND [base $XXXX]`):
  `bytes`, `words` (labels or raw values), `offsets`, `stream` (the player's own items: note names, named commands
  with `:XX` arguments), and for awbt `song`, `seq` and `voice`; `-: bytes` for bytes nothing points to. Text ->
  bytes checks that each table the code reads lands back at its address.
- Packed music: zyxtvmbt's compiled STC (and zyxremix's whole image) are packed by `tools/lzpack.py` in the build
  (the variant's `packed` key); the tune itself is `stc.txt` like the others.
