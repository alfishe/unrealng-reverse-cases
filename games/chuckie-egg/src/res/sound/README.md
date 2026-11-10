# Sound

Text files; each head explains its format.

| File | Address | Bytes | Readers | What |
| --- | --- | ---: | --- | --- |
| `TitleTune.txt` | `$AE0C-$AE69` | 94 | PlayTune `$AB60` from TitlePage `$A420` (once a run: TitleTuneDone `$736F`) | 46 (duration, pitch) notes and the closing 0 0; BEEP `$03F8` through the ROM calculator (TuneCalc `$AB6D` divides the duration by ten) |
| `DeathTune.txt` | `$AE6A-$AE9B` | 50 | PlayTune `$AB60` from LifeLost `$A6FE` | 24 notes and 0 0 |
| `Phrases.txt` | `$C8C8-$CBC3` | 764 | StartPhrase `$9CEB` (the word at `$C8C6` + 2N, phrase N = 1-32), PhraseInterrupt `$9CC2` (IM 2 through `$9C9C`: OUT (`$9F`) one allophone, then wait its count of interrupts; `$FF` ends) | the table of 33 words, 34 pad bytes, the phrases as (count, SP0256-AL2 allophone) pairs; phrase 20, the title, says "A and F software presents Chuckie Egg" |

The pickers LiftPhrase `$A389`, DeathPhrase `$AAE4` and LevelPhrase `$B14F` choose the phrase number from
`../tables/*Phrases.csv` with R AND 7.
