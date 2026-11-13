# texts

The game's texts in hex text: `"text"` for printable runs (3 or more characters `$20-$7E`), two hex digits for any other
byte (the print records' attribute | `$80`, column and row, `$FF` the end, the COMPUTER line's control bytes and loop
words); `$ADDR:` at a line's start and `#` lines are comments. Keep each file's length: the code and the loop words
address bytes inside them. The font is graphics/font.png (characters 32-127).

| File | Address | Size | What | Read by |
| --- | --- | --- | --- | --- |
| practice.txt | `$8A9D` | 36 | PracticeText: the practice line on row 19 of the play area | PrintPlay `$8E47` |
| intermission.txt | `$972B` | 15 | IntermissionText: the pause's banner | the pause `$973F` |
| options.txt | `$9F49` | 154 | HallOfFameTitle and OptionsText: the hall of fame's title, the logo and the options | PrintFull `$8E3A` |
| hall-of-fame.txt | `$9FEB` | 104 | HallOfFameScores and HallOfFameNames: the six records | PrintFull `$8E3A`, HallOfFame |
| messages.txt | `$A112` | 488 | the COMPUTER line's messages DemoMessage to IntermissionLoop: static and scrolling texts, their loop words | the COMPUTER line (MessageNumber `$A104`) |
| ending.txt | `$A984` | 259 | EndingText: the ending's text records | PrintFull `$8E3A` |
