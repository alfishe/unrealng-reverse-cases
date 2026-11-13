# Resident: the print font, the texts, the stages, the AY effects and the tables

The data of the resident `$F000-$FFFF` (src/resident/resident.ann). The formats are in tools/res_resident.py (its
docstring has the details); `python3 tools/res_formats.py build` turns each file back into the bytes the sources
`INCBIN`.

| File | Address | Bytes | Format | Read by |
| --- | --- | ---: | --- | --- |
| print-font.png | `$F880` (PrintFont) | 296 | 37 glyphs (A-Z, space, 0-9) of 8 bytes in a row of 8 x 8 cells, grey lines between; each cell's top row is the width mask (red: its lowest set bit is the glyph's last column), rows 1-7 the glyph | TextToBuffer `$F3CB`, Advance `$F465` |
| text-rewind.txt | `$F04E` | 19 | `column`, `bit`, `row` (pixel row), `text`: a Print string | RestartFromStageOne `$F048` (Print `$F3B0`) |
| text-press-play-again.txt | `$F064` | 23 | the same: AND THEN PRESS PLAY | RestartFromStageOne |
| text-press-play.txt | `$F1DF` | 22 | PRESS PLAY ON TAPE | PlayStage `$F1CA` |
| text-clear-line.txt | `$F1FB` | 5 | a space: clears the PRESS PLAY line | PlayStage |
| text-game-over.txt | `$F26C` | 13 | GAME OVER | GameOver `$F24B` |
| text-press-space.txt | `$F27C` | 25 | PRESS SPACE TO SELECT | GameOver |
| text-restart-stage.txt | `$F2FA` | 22 | RESTART THIS STAGE | PrintGameOverMenu `$F2F7` |
| text-restart-from-one.txt | `$F313` | 26 | RESTART FROM STAGE ONE | PrintGameOverMenu |
| text-credits-score.txt | `$F330` | 37 | GAME CREDITS n and SCORE nnnnnn: the digits are written by GameOver (CreditsDigit `$F340`, ScoreDigits `$F34E`) | PrintGameOverMenu |
| text-clear-top.txt | `$F602` | 5 | a space at row 36 | LoadStage `$F5E4` |
| text-stop-tape.txt | `$F60A` | 17 | STOP THE TAPE | LoadStage |
| stages.txt | `$F0EA` (StageTable) | 224 | per stage: `load D E C H L B` (C the stage number, the length 2 x (9B + H + L) pages of 256 bytes; D and E not read) and two `title COLUMN BIT ROW "TEXT"` lines | PlayStage `$F1CA` (the load data at `$F211`, the titles by PrintRecord `$F3BD`) |
| effects.csv | `$F54D` (EffectData) | 138 | `effect,channel,noise,volume,period,segments`: channel 1-3, noise 0 (a tone) or not (noise: the period's low byte is the noise period), volume x 16, the tone period, then `duration/period change/volume change` per segment | StartEffect `$F6D5` (through EffectTable `$F6BB`), ChannelStep `$F7DE` |
| colour-cycle.csv | `$F374` (ColourCycle) | 8 | `ink,paper,bright,flash`: one attribute a frame | CycleColours `$F356` |
| dissolve-masks.txt | `$F9CB` (DissolveMasks) | 48 | 6 sets of 8 masks in binary, each set growing to `11111111` | RevealText `$F483` (sets 0-3), the front's reveals |
| bit-reverse.txt | `$FA00` (BitReverse) | 256 | each byte in binary and its mirror | the stages (c1, deaths, s1-s3 read it) |
| screen-lines.csv | `$FB00` (ScreenLineTable) | 384 | `line,address`: the screen address of each pixel line | RevealText, the front, the stages |
| rom-font-leftover.png | `$FF84` (RomFontLeftover) | 124 | one 8-pixel-wide strip, a byte a line: the ROM font's `$3E34-$3EAF` and a `$27` | no code: a leftover of the mastering |

The bytes no code reads elsewhere in the resident are named entries of resident.ann: ResidentInitPad `$F019`,
EffectLeftover `$F5D7`, MixerSpare `$F877`, LoadLengthPad `$F87C`, DecimalTablePad `$F9C9`, ResidentVarsPad
`$F9FE`, ScreenLineTablePad `$FC80`, KeyXorMaskPad `$FCFB`.
