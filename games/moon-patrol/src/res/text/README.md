# Texts

Every print string of the game as UTF-8 text. `tools/res_formats.py` turns each file back into the bytes PrintText
`$FFD0` reads: characters `$20-$7E` as themselves (`$60` as the pound sign, `$7F` as the copyright sign), the control
codes as `{INK n}`, `{PAPER n}`, `{FLASH n}`, `{BRIGHT n}` (`$10-$13`), `{AT x,y}` (`$16`, pixels), `{TAB x}`,
`{MARGIN n}`, `{LIMIT n}`, `{FONT n}` (`$17-$1A`), `{CR}` (`$0D`), `{END}` (`$1F`, the terminator, followed in the file by
a line break that is not data), any other byte as `{$XX}`. Numbers are decimal.

Strings kept as plain `DEFM` in the source, not here: the hi-score table's names (GreatestName `$88AD`,
GreatestInitials `$88C6`: part of the table saved to tape) and the leftovers no code reads (CopyrightLeftover
`$7FBF`, BuildTag `$FFF7`).

| File | Address | Bytes | Format | Readers | What |
| --- | --- | ---: | --- | --- | --- |
| `BuildDate0335.txt` | `$7F00-$7F13` | 20 | print string | LifeStart (PrintText `$FFD0`) | A print string with the build date 03:35 30/10/84, printed at each life start; its first byte `$1F` ends it at once |
| `TitleText.txt` | `$8413-$84F9` | 231 | print string | TitlePage (PrintText `$FFD0`) | The title page text: the copyright line, "Press S to start." and the key list |
| `OptionsText.txt` | `$84FA-$8654` | 347 | print string | OptionsPage (PrintText `$FFD0`) | The options page text: SELECT OPTIONS, the players, the courses, the six controls, the keys |
| `ScoreAdvanceText.txt` | `$8655-$8705` | 177 | print string | ScoreAdvancePage (PrintText `$FFD0`) | The score advance table's text: the title, the underline and the points of each enemy (shot / jumped) |
| `DemoText.txt` | `$8706-$8715` | 16 | print string | DemoPage (PrintText `$FFD0`) | "DEMO" in font 1, then font 2 selected |
| `TapeErrorText.txt` | `$8716-$873A` | 37 | print string | MenuCheckTape (PrintText `$FFD0`) | "Tape error - hit any key.": printed by TapeFailed when a load or verify fails, never read |
| `RobotronWarningText.txt` | `$873B-$87AB` | 113 | print string | MenuCheckTape (PrintText `$FFD0`) | "WARNING- You have attempted to load an Atarisoft Robotron hi-score table. Please try again!!!", never read |
| `HeroesTitleText.txt` | `$89DA-$89FD` | 36 | print string | HeroesDrawTables (PrintText `$FFD0`) | "MOON PATROL HEROES" |
| `AllTimeTitleText.txt` | `$89FE-$8A1E` | 33 | print string | HeroesDrawTables (PrintText `$FFD0`) | "ALL TIME HEROES" and "1) " for THE GREATEST |
| `HeroesTapeKeysText.txt` | `$8A1F-$8A4B` | 45 | print string | HeroesDrawTables (PrintText `$FFD0`) | "L=LOAD, J=SAVE, G=VERIFY HI-SCORES." at the foot of the page |
| `HiScoreTexts.txt` | `$8DB1-$8E4D` | 157 | print string | GreatestEntry, HiScoreEntry (PrintText `$FFD0`) | The texts of the hi-score entry, printed in pieces; first INK 6 BRIGHT 1, printed after the player number |
| `TextPlayer.txt` | `$9073-$9085` | 19 | print string | GameStart (PrintText `$FFD0`) | Print string (PrintText `$FFD0`): white on black, AT x `$68` y `$55`, font 1, "PLAYER " (the digit follows) |
| `TextGameOver.txt` | `$9086-$909A` | 21 | print string | GameAfterLife (PrintText `$FFD0`) | Print string: AT x `$65` y `$55`, font 1, "GAME OVER" (one player) |
| `TextGameOverPlayer.txt` | `$909B-$90B7` | 29 | print string | GameAfterLife (PrintText `$FFD0`) | Print string: AT x `$4B` y `$55`, font 1, "GAME OVER PLAYER " (the digit follows) |
| `TextNoDate.txt` | `$90B8-$90B8` | 1 | print string | LifeStart (PrintText `$FFD0`) | An empty print string (`$1F` only): LifeStart prints it, and the build stamp after it is never printed |
| `BuildStamp.txt` | `$90B9-$90CB` | 19 | print string | never printed | A build time stamp, never printed: `$00` `$21`, font 2, "20:15 29/10/84", `$1F` |
| `HudTextLamps.txt` | `$93D3-$93F3` | 33 | print string | HudDraw (PrintText `$FFD0`) | Print string: ink 1 paper 1, AT x `$E0` y 2 "DANGER!", AT x `$E0` y `$0A` "CAUTION" (the lamp texts) |
| `HudText1P.txt` | `$93F4-$93F8` | 5 | print string | HudDraw (PrintText `$FFD0`) | Print string: font 2, "1P" (HudDraw puts the position first) |
| `HudText2P.txt` | `$93F9-$93FE` | 6 | print string | HudDraw (PrintText `$FFD0`) | Print string: AT x 2 y `$11`, "2P" (two players only: p2 9 reads) |
| `HudTextTimePoint.txt` | `$93FF-$940E` | 16 | print string | HudDraw (PrintText `$FFD0`) | Print string: AT x `$9B` y 1 "TIME", AT x `$9E` y 9 "POINT" |
| `HudTextBeginner.txt` | `$940F-$941A` | 12 | print string | HudDraw (PrintText `$FFD0`) | Print string: AT x `$9B` y `$11` "BEGINNER" (game 21 reads) |
| `HudTextChampion.txt` | `$941B-$9426` | 12 | print string | HudDraw (PrintText `$FFD0`) | Print string: AT x `$9B` y `$11` "CHAMPION" (read i1 1: the Champion course after Z; i2 11) |
| `HudTextPointAt.txt` | `$9427-$942C` | 6 | print string | HudPrintPoint (PrintText `$FFD0`) | Print string: AT x `$C2` y 9, font 2 (the point letter follows: HudPrintPoint) |
| `TextPointAt.txt` | `$97A7-$97AC` | 6 | print string | CmdPoint (PrintText `$FFD0`) | Print string: AT x `$F9` y `$B1`, font 2 (CmdPoint prints the point letter after it) |
| `BonusHeaderText.txt` | `$A6A0-$A705` | 102 | print string | SectorBonus (PrintText `$FFD0`) | The bonus screen's three labels: TIME TAKEN TO REACH POINT, TIME REQUIRED FOR BONUS, BEST TIME SO FAR |
| `SectorBonusText.txt` | `$A706-$A718` | 19 | print string | SectorBonus (PrintText `$FFD0`) | SECTOR BONUS = at x `$46`, y `$69` |
| `TimeBonusText.txt` | `$A719-$A72B` | 19 | print string | SectorBonus (PrintText `$FFD0`) | TIME BONUS   = at x `$46`, y `$71` |
| `NoTimeBonusText.txt` | `$A72C-$A742` | 23 | print string | SectorBonus (PrintText `$FFD0`) | SORRY NO TIME BONUS at x `$46`, y `$71` (never read in the recordings) |
| `BestTimeText.txt` | `$A743-$A772` | 48 | print string | SectorBonus (PrintText `$FFD0`) | AWESOME! BEST SECTOR TIME SO FAR!! in its own colours (`$10` ink 4, `$11` paper 0, `$13` bright 1) at x `$1C`, y `$81` (never read in the recordings) |
| `BuildDate0245.txt` | `$B2C2-$B2D5` | 20 | print string | LifeStart (PrintText `$FFD0`) | A print string with the build date 02:45 29/10/84, disabled like BuildDate0335 `$7F00` |
| `PrintResetText.txt` | `$FFE7-$FFF2` | 12 | print string | PrintReset (PrintText `$FFD0`) | INK 0, AT 0 0, MARGIN 0, LIMIT `$FF`, FONT 3, end (`$12` 00 16 00 00 18 00 19 FF 1A 03 1F) |
