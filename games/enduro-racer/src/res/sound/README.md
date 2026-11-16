# sound

| File | Entry | Format |
| --- | --- | --- |
| `notes.csv` | `NoteTable` `$66AA-$66C1` | `period`: the AY tone period of each semitone (word n for note n; word 0 never read) |
| `tunes.txt` | `Tune2A` `$66CA-$67FA` (Tune2A, Tune1A, Tune2B, Tune1B and their phrases) | the channel streams as commands; the format is in the file's header (PlayChannel) |

Tune 1 plays on stages 1, 3 and 5, tune 2 on 2 and 4 (SetTune). The engine, the crash noise and the beeps are code,
not data (sound module).
