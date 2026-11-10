# Text

UTF-8 text. The quoted-string files hold one string a line: printable ASCII as itself, `·` (U+00B7) code 0,
`０`-`９` (U+FF10-U+FF19) the HUD digit codes `$9E-$A7`, `\xNN` any other byte, `\"` and `\\` escaped
(`res_formats.py` CHARMAP); the build writes the game's codes back. Pages stored bottom row first are written top row
first. Each file's head names its layout.

| File | Address | Bytes | Readers | What |
| --- | --- | ---: | --- | --- |
| `KeySets.txt` | `$8250-$8273` | 36 | SetupLevel `$AE9C` (copies set KeyType into KeyTable `$732E`), RedefineKeys `$AA49` / RedefineOne `$AB19` (write set 3) | the three key sets as key names: 1 = 2 W 9 0, jump Z / M; 2 = 7 6 5 8, jump 4 / 9; 3 = Q A O P, jump M / 1 |
| `MenuLeftover.txt` | `$8336-$838F` | 90 | none (L1: no access) | leftover: three earlier menu lines, zeros for spaces |
| `InstructionsText.txt` | `$8390-$84EF` | 352 | InstructionsPage `$A4C8` (row k at character row 3 + 2k); RedefineKeys writes `$83F6`-`$840A` | the instructions page, 11 rows of 32 |
| `TitleText.txt` | `$9630-$9763` | 308 | TitlePage `$A420` (row k at row 2 + k, columns 0-13) | the title page's left half, 22 rows of 14; `\x80`-`\x8A` the big CHUCKIE EGG |
| `HudText.txt` | `$9764-$9786` | 35 | SetupLevel `$AE9C` (writes the digits first: `$976B`, `$9772-$9773`, `$977A`, `$9784`) | SCORE for the top row, the 32 codes of the third row |
| `HiScoreTable.txt` | `$97AF-$984E` | 160 | DrawHiScores `$ABAD`, EnterHiScore `$A80C` (compares `$97B9` + 16k, shifts, writes) | the default ten entries: name, six ASCII digits |
| `MenuTexts.txt` | `$ABF2-$AD66` | 373 | DrawHiScores, RedefineKeys, RedefineOne (KeyNames `$AC54`), TitleLoop `$A47D` and InstructionsPage (the scrollers), StartGame `$A59D`, Message `$A9CE`; PlayerTurn writes `$AD50`, PlayLevel `$AD58-$AD59` | the high-score title, the redefine prompt and key labels, the key names, two scroller texts, the players prompt, the messages |
| `Congratulations.txt` | `$AD67-$AE0B` | 165 | EnterHiScore `$A80C` (row k at row 23 - 2k); GameOver `$A7BC` writes `$AD72` | the name entry page, 11 rows of 15 |
| `SourceLeftoverB167.txt` | `$B167-$B1FF` | 153 | none (L1: no access) | leftover: the author's assembler source (a scroller, SCRL2 / SCROL), BCD line numbers |
| `SourceLeftoverB307.txt` | `$B307-$B34B` | 69 | none | leftover source text |
| `SourceLeftoverB381.txt` | `$B381-$B3AF` | 47 | none | leftover source text |
| `SourceLeftoverC8B0.txt` | `$C8B0-$C8C7` | 24 | none | leftover source text |

The four source leftovers are lines of the author's assembler file (a line number in BCD, the length, the text),
left in the image when it was saved (known only from the bytes); the build turns the readable lines back into the same bytes. Between
`$B34C` and `$B380`, inside this text, lies FallOffEdge `$B34C`, code that runs (see `src/game/leveldata.asm`).
