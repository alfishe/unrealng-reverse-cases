# 11. Data reference

Every data entry of the game image `$8214`-`$CBE7`, in address order by module (`src/game/<module>.asm`):
tables, buffers, records, variables, graphics, text; an inner label (a field, a row) is a row of its own under
its entry, its size up to the next label. The name, the title and the description are the
source's (`src/game/game.ann`); the readers and writers are the routines the recordings saw touch it
(`work/game`, local and not in the repository), and, marked
"(code)", the routines whose `LD` through `(nn)` reads or writes it where the recordings did not see them do so.
Written by `kit/refdocs.py`.

## tables

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$8214` | `LeftoverMapRow` | 60 | Leftover: a piece of a map row (a ladder 01 02, the cage's codes `$A8` `$A9`). Never read or written (L1 of the eight builds: no access). The bytes look like a row of a level map (LevelMaps `$B3B0` codes: 1 and 2 a ladder, `$A8-$A9` the cage's top), left from an earlier layout of the image. | - | - |
| `$8250` | `KeySets` | 36 | The three key sets: (mask, port row) for up, down, left, right, jump, jump. SetupLevel `$AE9C` copies one set into KeyTable at every level start: type 1 (`$8250`, KeyType 6, the default) 2 W 9 0 and jump Z or M; type 2 (`$825C`, KeyType 5) 7 6 5 8 (the cursor joystick) and jump 4 or 9; type 3 (`$8268`, KeyType 3) the set RedefineKeys `$AA49` writes (Q A O P, jump M or 1 in the image). A key is down when (IN (row x 256 + `$FE`) AND `$1F`) OR mask is not `$1F`. The editable form is src/res/text/KeySets.txt. Witness: SetupLevel's copy runs 35 times in the eight builds (tools/l1count.py `$B0B8`); tour-type2 reads `$825C`, tour-redefine writes `$8268-$8271` (RedefineKeys clears ten bytes, RedefineOne writes five keys). | `SetupLevel` | - |
| `$825C` | `KeySet2` (`KeySets`+12) | 12 | type 2: the cursor keys | - | - |
| `$8268` | `KeySet3` (`KeySets`+24) | 12 | type 3: the set R redefines (its last pair, the second jump key, is never redefined) | `SetupLevel` | - |
| `$8274` | `Zeros8274` | 194 | 194 zeros. Never read (L1: no access). | - | - |
| `$8336` | `MenuLeftover` | 90 | Leftover: three menu lines with zeros for spaces. Never read (L1: no access). Text of an earlier menu (src/res/text/MenuLeftover.txt); the game's menu texts are MenuTexts `$ABF2`. | - | - |
| `$8390` | `InstructionsText` | 352 | The instructions page: 11 rows of 32, the bottom row first. InstructionsPage `$A4C8` prints row k at character row 3 + 2k (from the bottom), so the page fills every other row of the screen; the editable form is src/res/text/InstructionsText.txt (top row first). RedefineKeys `$AA49` and RedefineOne `$AB19` write the new key names into row 3 of the page (`$83F6`, `$83FB`, `$8400`, `$8405`, `$840A`: up, down, left, right, jump), so the page shows the redefined set. Witness: InstructionsPage runs in c1, idle-1p, tour-type2 and tour-redefine; tour-redefine writes the five bytes. | `TitlePage` | - |

## graphics

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$84F0` | `CharacterSet` | 1264 | The character set, codes 0-`$9D`: the map cells, the font, the title logo. Glyph = CharacterSet + 8 x code, top row first. Codes 0-5 are the map cells (empty, the ladder's two halves, the egg, the grain, the brick), `$20-$7F` the font (`$41-$5A` thin capitals, `$61-$7A` bold capitals, no lower case; `$7E` (R), `$7F` (C)), `$80-$8E` the quadrant blocks of the big CHUCKIE EGG of the title (TitleText uses `$80-$8A`), `$8F-$96` the small A+F CHUCKIE EGG of the default names, `$97-$9A` the key names SPACE, CAPS SHIFT, SYMBOL SHIFT and ENTER, `$9B-$9D` LEVEL. Readers: PrintChar `$9C40` (33 112 calls), DrawSprite `$9A4C` (the background cells), DrawHen `$929C` (the cells it erases, from `$84F7`, the last row), AddScore `$A3A7` (the digits `$30-$39` at `$8670`). | `AddScore`, `DrawHen`, `DrawSprite`, `PrintChar` | - |
| `$89E0` | `HudCharacters` | 368 | Codes `$9E-$CB`: the HUD digits, the cage, the life icon, the cursor, the small A&F SOFTWARE. The tail of the character set: `$9E-$A7` the digits 0-9 of the HUD (CountDown `$A1B8` reads them as HudCharacters + 8 x digit), `$A8-$B5` the duck's cage, `$B6` the life icon, `$B7` the name entry's cursor, `$B8-$CB` the small A&F SOFTWARE. The digits are 7 rows under a blank top line, not larger than the font's `$30-$39`. | `CountDown`, `DrawSprite`, `PrintChar` | - |
| `$8B50` | `FillFF` | 672 | 672 bytes: 416 of `$FF`, then 256 of 0. Never read (L1: no access): the size of one level map. | - | - |
| `$8DF0` | `Sprites` | 544 | The 17 sprite frames of 16 x 16: Harry right 0-3, left 4-7, the duck 8-11, blank 12, climbing 13-16. DrawSprite `$9A4C` copies frame A (Sprites + 32 x A, two bytes a row, top row first). Harry's frame is HarryFrame + HarryDir (0 right, 4 left, `$0D` climbing), the duck's 8 or 10 + DuckFrame (10-11 when Harry is left of it); frame 12 (blank) erases Harry when he lands on a lift and the duck before it moves. Harry walks with 0, 1, 0, 3: frame 2 is a byte-for-byte copy of 0; the left frames are the right ones mirrored bit for bit; Harry's frames leave row 0, row 15 and two columns each side blank, which is why a one-pixel move needs no erase. Witness: DrawSprite runs 134 270 times in the eight builds. | `DrawSprite` | - |
| `$9010` | `HenSprites` | 256 | The hens' eight frames of 16 x 16: walking 0, 1, 4, 5, climbing 2-3, pecking 6-7. DrawHen `$929C` reads frame A - 1 from its last row up (HL = HenSprites - 2 + 32 x A). For a walk A is the state (1 left, 2 right) plus 4 when x AND 4 is set; for a climb 3, or 4 when y AND 4 is set; the pecks 7 and 8 are frames 6 (left) and 7 (right). Frames 0-1 fill columns 0-7, frames 4-5 (the next step of the same walk) columns 4-11: DrawHen writes whole bytes at x >> 3, so frames 4-5 are the walk pre-shifted by half a byte, the only stored shift in the game. | `DrawHen` | - |
| `$9110` | `LeftoverSprite` | 14 | Leftover: the first rows of a sprite frame. Never read (L1: no access). | - | - |

## hens

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$943E` | `LeftoverCode943E` | 29 | Leftover: copies of code bytes from an earlier assembly. Never read (L1: no access). F1 C9 E5 CD 34 9E E1 C9 is the end of ScreenAddr and MapCellPeek (`$9436-$943D`), the rest the middle of ScreenAddr (`$940C-$9421`), shifted by an earlier layout. | - | - |
| `$945B` | `HenTable` | 189 | The hens of levels 1-8: a count, then up to five hen records. SetupLevel `$AE9C` reads the row at `$945B` + 21 x ((Level AND 7) + 1), so row 0 here (`$945B`) is never read: level 1's row is `$9470`. The first byte is the number of bytes to copy into Hens (8 on level 1, 12 on 2-3, 16 on 4-6, 12 on 7-8: two to four hens), then the records (x, y, state, spare). Levels 9-16 copy none, 17-24 the table again, 25 and up all 20 bytes (five hens). The editable form is src/res/tables/HenTable.csv. Witness: SetupLevel's copy at `$AFA4`: 35 levels in the eight builds. | `SetupLevel` | - |
| `$9518` | `Zeros9518` | 32 | 32 zeros. Never read (L1: no access). | - | - |

## render

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$95C5` | `Zeros95C5` | 107 | 107 zeros. Never read (L1: no access). | - | - |

## screens

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$9630` | `TitleText` | 308 | The title page's left half: 22 rows of 14 codes, the bottom row first. TitlePage `$A420` prints row k at character row 2 + k from the bottom, columns 0-13; codes `$80-$8A` are the big CHUCKIE EGG (its only codes from `$80` up; the small A+F CHUCKIE EGG `$8F-$96` is in HiScoreTable). The editable form is src/res/text/TitleText.txt (top row first). Witness: TitlePage runs 4 times in the eight builds. | `Start` | - |
| `$9764` | `HudText` | 35 | The HUD: the SCORE label for the top row, 32 codes for the third. SetupLevel `$AE9C` prints the first three (SCORE, codes `$0B-$0D`) at character row 23 (the top), the 32 at row 21: PLAYER (`$0E-$11`), LEVEL (`$9B-$9D`), BONUS (`$1B-$1D`) and TIME (`$12-$14`), each with its digits. It writes the digits first: `$976B` the player, `$9772-$9773` the level, `$977A` the bonus's thousands, `$9784` the time's hundreds (codes `$9E` + digit, HudCharacters); the image holds level 1's. | `SetupLevel` | `SetupLevel` |
| `$976B` | `HudPlayer` (`HudText`+7) | 7 | the player's digit | `SetupLevel` | `SetupLevel` |
| `$9772` | `HudLevel` (`HudText`+14) | 8 | the level's two digits | `SetupLevel` | `SetupLevel` |
| `$977A` | `HudBonus` (`HudText`+22) | 10 | the bonus's thousands digit | `SetupLevel` | `SetupLevel` |
| `$9784` | `HudTime` (`HudText`+32) | 3 | the time's hundreds digit | `SetupLevel` | `SetupLevel` |
| `$9787` | `LiftTable` | 36 | The lifts: the record in play, then one a level (1-8). A record is the screen address of the platform's start (two bytes), the lift's x (`$FF`: no lift) and its height count at the start (3). SetupLevel `$AE9C` copies level (Level AND 7) + 1's record over the first one and into Lift1; MoveLifts `$A014` restarts a platform from the first one when it reaches the top. Lifts on levels 3-7 (x `$40`, `$90`, `$C8`, `$78`, `$F0`), none on 1, 2 and 8. The editable form is src/res/tables/LiftTable.csv. Witness: the restarts `$A02E` (164) and `$A05C` (167) in levels-1-3, gameover-name and levels-1-9. | `SetupLevel` | `SetupLevel` |
| `$97AB` | `Leftover97AB` | 4 | Leftover bytes. Never read (L1: no access). | - | - |
| `$97AF` | `HiScoreTable` | 160 | The ten best scores: ten name bytes and six digits each, the best first. DrawHiScores `$ABAD` prints the table; EnterHiScore `$A80C` compares a score with each entry's digits (`$97B9` + 16 k), shifts the lower entries down and writes the new one. The digits are ASCII (`$30-$39`), as GameOver `$A7BC` makes the scores. The editable form is src/res/text/HiScoreTable.txt. Witness: gameover-name writes one entry. | `DrawHiScores` | - |
| `$984F` | `CellAttributes` | 9 | The attribute of map cell codes 0-8. PaintCells `$9538`, EraseHen and SetupLevel `$AE9C` read CellAttributes + code (codes 9 and up take 6, yellow): empty 6, the ladder 3 and 3 (magenta), the egg 7, the grain 3, the brick 4 (green), then 6, 7, 7. The editable form is src/res/tables/CellAttributes.csv. | `DrawHen`, `PaintCells`, `SetupLevel` | - |

## mainloop

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$9A2C` | `LeftoverCode9A2C` | 32 | Leftover: two copies of the end of TakeGrain, then zeros. Never read (L1: no access). A3 21 FF FF 22 45 73 7D 32 70 73 C9 is TakeGrain's tail (`$9A1F-$9A2B`), twice. | - | - |

## sprite

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$9BFF` | `Zeros9BFF` | 65 | 65 zeros. Never read (L1: no access). | - | - |

## sound

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$9C8E` | `LeftoverCode9C8E` | 14 | Leftover: POP BC, POP HL, RET, then zeros. Never read (L1: no access): the end of an older PrintChar. | - | - |
| `$9C9F` | `Zeros9C9F` | 5 | 5 zeros. Never read (L1: no access). | - | - |
| `$9CB5` | `Zeros9CB5` | 13 | 13 zeros. Never read (L1: no access). | - | - |
| `$9D06` | `Zeros9D06` | 2 | 2 zeros. Never read (L1: no access). | - | - |

## harry

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$9DF1` | `Zeros9DF1` | 67 | 67 zeros. Never read (L1: no access). | - | - |
| `$9E57` | `LeftoverCode9E57` | 15 | Leftover: POP HL, RET, then zeros. Never read (L1: no access). | - | - |
| `$9E8D` | `Zeros9E8D` | 11 | 11 zeros. Never read (L1: no access). | - | - |
| `$9F3F` | `Zeros9F3F` | 33 | 33 zeros. Never read (L1: no access). | - | - |
| `$9FDF` | `Zeros9FDF` | 53 | 53 zeros. Never read (L1: no access). | - | - |

## lifts

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$A0C0` | `LeftoverCodeA0C0` | 8 | Leftover: LD A,H, SUB 8, LD H,A, RET and three bytes. Never read (L1: no access). | - | - |

## duck

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$A19A` | `ZerosA19A` | 30 | 30 zeros. Never read (L1: no access). | - | - |

## timers

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$A21A` | `LeftoverA21A` | 2 | Leftover: RET, 0. Never read (L1: no access). | - | - |

## jump

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$A399` | `LiftPhrases` | 8 | The phrases LiftPhrase picks from. Read at LiftPhrases + (R AND 7) (LiftPhrase steps (R AND 7) + 1 bytes from LiftPhrases - 1). The editable form is src/res/tables/LiftPhrases.csv. | - | - |
| `$A3A1` | `LeftoverA3A1` | 6 | Leftover: RET, LD C,A, INC B, RET, 0, 0. Never read (L1: no access). | - | - |

## score

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$A40F` | `LeftoverA40F` | 1 | A zero. Never read (L1: no access). | - | - |

## menudata

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$AB6D` | `TuneCalc` | 3 | The calculator's program: stk-ten, division, end-calc. Run by RST `$28` at `$AB6C` (read by the ROM's calculator). | - | - |
| `$ABEA` | `DeathPhrases` | 8 | The phrases DeathPhrase picks from. Read at DeathPhrases + (R AND 7). The editable form is src/res/tables/DeathPhrases.csv. | - | - |
| `$ABF2` | `MenuTexts` | 373 | The menu's texts: the high score title, the redefine page, the scrollers, the messages. The editable form is src/res/text/MenuTexts.txt. The code writes PlayerMessage + 7 (the player's digit, PlayerTurn) and LevelDigits (PlayLevel). | `DrawHiScores`, `TitlePage` | `TitlePage`, `PlayLevel` (code), `PlayerTurn` (code), `StartGame` (code) |
| `$AC02` | `RedefinePrompt` (`MenuTexts`+16) | 32 | the redefine prompt (32) | - | - |
| `$AC22` | `KeyLabels` (`MenuTexts`+48) | 50 | the five key labels (10 each) | - | - |
| `$AC54` | `KeyNames` (`MenuTexts`+98) | 40 | the key names: 8 port rows of 5, `$7FFE` first | - | - |
| `$AC7C` | `TitleScroller` (`MenuTexts`+138) | 78 | the title scroller (78) | `TitlePage` | - |
| `$ACCA` | `InstructionsScroller` (`MenuTexts`+216) | 87 | the instructions scroller (87) | `TitlePage` | - |
| `$AD21` | `PlayersPrompt` (`MenuTexts`+303) | 30 | the players prompt (29) | `TitlePage` | - |
| `$AD3F` | `GameOverMessage` (`MenuTexts`+333) | 10 | GAME OVER (9), then PLAYER n | - | - |
| `$AD49` | `PlayerMessage` (`MenuTexts`+343) | 9 | PLAYER n (8) | - | `PlayerTurn` (code) |
| `$AD52` | `LevelMessage` (`MenuTexts`+352) | 6 | LEVEL (6) | - | - |
| `$AD58` | `LevelDigits` (`MenuTexts`+358) | 2 | the level's two digits | - | `TitlePage`, `PlayLevel` (code), `StartGame` (code) |
| `$AD5A` | `OutOfTimeMessage` (`MenuTexts`+360) | 13 | OUT OF TIME ! (13) | - | - |
| `$AD67` | `Congratulations` | 165 | The name entry page: 11 rows of 15. EnterHiScore prints row k at row 23 - 2k; GameOver writes the player's digit at `$AD72`. The editable form is src/res/text/Congratulations.txt. | - | `GameOver` (code) |
| `$AE0C` | `TitleTune` | 94 | The title tune: 46 (duration, pitch) notes, 0 0. The editable form is src/res/sound/TitleTune.txt. | `PlayTune` | - |
| `$AE6A` | `DeathTune` | 50 | The tune of a life lost: 24 notes, 0 0. The editable form is src/res/sound/DeathTune.txt. | `PlayTune` | - |

## leveldata

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$B15F` | `LevelPhrases` | 8 | The phrases LevelPhrase picks from. Read at LevelPhrases + (R AND 7). The editable form is src/res/tables/LevelPhrases.csv. | `LevelPhrase` | - |
| `$B167` | `SourceLeftoverB167` | 153 | Leftover: the author's assembler source. Never read (L1: no access). Lines of an earlier program (a scroller: SCRL2, SCROL), with BCD line numbers; src/res/text/SourceLeftoverB167.txt. | - | - |
| `$B200` | `VectorTable` | 263 | The IM 2 vector table: 263 bytes of `$9C`. I = `$B2` (Start): an interrupt with `$FF` on the bus reads `$B2FF-$B300`, `$9C9C`, PhraseVector. Witness: only `$B2FF-$B300` are read (243 240 reads). | `PhraseVector` | - |
| `$B307` | `SourceLeftoverB307` | 69 | Leftover: the author's assembler source. Never read (L1: no access); src/res/text/SourceLeftoverB307.txt. | - | - |
| `$B381` | `SourceLeftoverB381` | 47 | Leftover: the author's assembler source. Never read (L1: no access); src/res/text/SourceLeftoverB381.txt. | - | - |
| `$B3B0` | `LevelMaps` | 672 | The eight level maps of 21 rows of 32 cells, the bottom row first: level 1. StartGame copies level 1 into every LiveMap slot, PlayLevel the next level's (LevelMaps + 672 x (Level AND 7)) into the map in play: levels 9-16 repeat 1-8, and so on. Codes: 0 empty, 1 and 2 a ladder, 3 an egg, 4 grain, 5 a brick, `$A8-$B5` the cage. The editable forms are src/res/maps/Level1.txt .. Level8.txt (top row first), the figures docs/img/maps. | `TitlePage` | - |
| `$B650` | `LevelMap2` | 672 | Level 2 | - | - |
| `$B8F0` | `LevelMap3` | 672 | Level 3 | - | - |
| `$BB90` | `LevelMap4` | 672 | Level 4 | - | - |
| `$BE30` | `LevelMap5` | 672 | Level 5 | - | - |
| `$C0D0` | `LevelMap6` | 672 | Level 6 | - | - |
| `$C370` | `LevelMap7` | 672 | Level 7 | - | - |
| `$C610` | `LevelMap8` | 672 | Level 8 | - | - |

## speech

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C8B0` | `SourceLeftoverC8B0` | 24 | Leftover: the author's assembler source. Never read (L1: no access); src/res/text/SourceLeftoverC8B0.txt. | - | - |
| `$C8C8` | `PhraseTable` | 764 | The addresses of the 33 phrases, 34 zero bytes, then their (timer, allophone) pairs. StartPhrase reads PhraseTable + 2 (N - 1). A phrase is pairs of (interrupts to wait, allophone), ended by `$FF`. Phrase 20 (the title) says "A and F software presents Chuckie Egg". The editable form is src/res/sound/Phrases.txt. | `PhraseInterrupt`, `StartPhrase` | - |
| `$CBC4` | `ZerosCBC4` | 36 | 36 zeros. Never read (L1: no access). | - | - |
