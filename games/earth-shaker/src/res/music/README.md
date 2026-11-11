# Music

PlayTune `$88CE` plays a tune of 4-byte notes `DRUM N1 N2 LENGTH`: DRUM 1 is a ROM BEEPER click (HL = `$020B`,
DE = 3) before the note, 2 a shorter one (HL = `$0106`, DE = 5), other values none; N1 and N2 are the two voices'
notes, periods NotePeriods[N]; LENGTH x 256 loop turns. The end record is DRUM and N1 = `$FF`, so a tune is 4k + 2
bytes. In the text: one note a line, decimal, and `end DRUM` last. Never played here: the facts come from the code
and the recordings' entry counts.

| File | Address | Bytes | Readers | What |
| --- | --- | ---: | --- | --- |
| `title.txt` | `$AD00-$B269` | 1386 | PlayTitleTune `$8A35`; MenuKeys `$8B29` compares PlayTune's end with `TitleTune+$0569` | the title tune |
| `win.txt` | `$6EF4-$72FD` | 1034 | PlayWinTune `$A615` | the tune after cave 32, 258 notes |
| `game-over.txt` | `$AA00-$AA4D` | 78 | PlayGameOverTune `$8B78` | the game-over tune |
| `life.txt` | `$AC5F-$ACFC` | 158 | PotionTune `$91C1` | the extra-life (potion) tune |
| `map.txt` | `$E8E8-$E9AD` | 198 | PlayMapTune `$E8E1` | the map screen's tune |
| `cave-1.txt` | `$BB80-$BBF9` | 122 | PlayCaveTune `$EE34` through CaveTunes | caves 1-4 |
| `cave-2.txt` | `$F100-$F151` | 82 | the same | caves 5-8 |
| `cave-3.txt` | `$F1D0-$F211` | 66 | the same | caves 9-12 |
| `cave-4.txt` | `$F212-$F297` | 134 | the same | caves 13-16 |
| `cave-5.txt` | `$F302-$F397` | 150 | the same | caves 17-20 |
| `cave-6.txt` | `$F398-$F49D` | 262 | the same | caves 21-24 |
| `cave-7.txt` | `$F298-$F301` | 106 | the same | caves 25-28 |
| `cave-8.txt` | `$F152-$F1CF` | 126 | the same | caves 29-32 |
| `cave-tunes.txt` | `$EE24-$EE33` | 16 | PlayCaveTune `$EE34` (word (CaveNumber - 1) / 4, `CaveTunes&255`, `CaveTunes/256`) | the tune of each group of four caves by name: an `@res ... include`, the build writes cave-tunes.inc with a DW line each |
| `periods.txt` | `$BC00-$BC91` | 146 | PlayNote `$8910` (`NotePeriods/256`) | 73 big-endian periods, note N at `$BC00` + 2N: `N PERIOD` a line |
