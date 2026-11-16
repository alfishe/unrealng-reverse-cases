# sound

| File | Address | Size | Readers |
| --- | --- | --- | --- |
| `tunes.txt` | NoteTable `$FB72-$FDFC` | 651 | TunePlay `$F852` (NoteLookup, NextSequenceA/B/D, the channel loops, Drums) |

The format is in the file's header. Two tunes: 0 the title (Title, through MenuLoop `$7391`: c1 2 calls) and 1 the
finish (TrailEnd `$ED00`: warp 7 calls). Each tune names three sequence lists (channel A, channel B, the drums);
a list is the patterns in turn (the channel starts it again at its end); a channel pattern is notes and commands
ending in `next`; a drum pattern is a byte every 12 interrupts (or as `speed` sets) ending in `next`.

The game's other sounds are code, not data: the engine (EngineSound `$D97C` from the interrupt, Tone with a half
period of `$1E` less the speed plus 1, three bursts a frame), the landing thump (Landing `$E663`: Tone then Noise),
the bonus count (CountBonus `$ED52`: a Tone a point). There is no crash or fuel sound.

**Leftovers.** The 3 bytes `$FDFA-$FDFC` after the last pattern (`bytes 008700`) and the drum commands' unused sounds
(DrumUnused `$FA50`, DrumUnused2 `$FA6C`: no tune uses commands 2 and 4).
