# Texts

| File | Address | Size | Contents |
| --- | --- | --- | --- |
| grid-text.txt | bank 6 `$C101-$C113` | 19 | GridText: Text: the two positions "00:00" at line $50 and line $70, column 1 |
| password-messages.txt | bank 6 `$C53E-$C577` | 58 | PasswordMessages: Texts: "INVALID PASSWORD", then two blank lines that clear it and the entry |
| password-prompt.txt | bank 6 `$C5EE-$C60D` | 32 | PasswordPrompt: Text: "Type in your level entry:-" |
| entry-string-text.txt | bank 6 `$C72A-$C749` | 32 | EntryStringText: Text: "THIS IS YOUR ENTRY STRING." |
| catalogue-magic.txt | bank 6 `$C881-$C88D` | 13 | CatalogueMagic: "MISSION:TAPE:": the first 7 bytes are compared with the catalogue's head |
| disk-texts.txt | bank 6 `$C8A0-$C977` | 216 | DiskTexts: Texts: "INCORRECT DISK", "INSERT DISK AND PRESS SPACE", the tape messages |
| failed-texts.txt | bank 6 `$CC94-$CD1D` | 138 | FailedTexts: Texts: "MISSION FAILED." and the five reasons |
| password-text.txt | bank 6 `$CEF6-$CF05` | 16 | PasswordText: Text: the password line; its ten characters at `$CEFB` |
| password-alphabet.txt | bank 6 `$CF5F-$CF82` | 36 | PasswordAlphabet: The 36 password characters: "9876543210ZYXWVUTSRQPONMLKJIHABCDEFG" |
| status-messages.txt | bank 6 `$D3EA-$D417` | 46 | StatusMessages: Texts: "TANK HAS BEEN HIT", "COLLISION OCCURED" |
| final-score-text.txt | bank 6 `$D418-$D46B` | 84 | FinalScoreText: Text: "MISSION COMPLETED:-", a blank line, "FINAL SCORE:-" and ten digits at `$D461` |
| status-text.txt | bank 6 `$D46C-$D4A4` | 57 | StatusText: Text: "MISSIONS COMPLETED" (code 8: MissionsCompleted), "SCORE TO DATE" and nine digits at `$D49A` |
| weapon-texts.txt | bank 6 `$D6DA-$D77E` | 165 | WeaponTexts: The weapon descriptions (Phoenix RRSA, Phoenix IRSA, Banshee IRSS, Dragonfly): name, weight, ammo, max |
| weapon-texts-b.txt | bank 6 `$D7BB-$D7E4` | 42 | WeaponTextsB: The Banshee RRSS description |
| weapon-texts-c.txt | bank 6 `$D7F4-$D935` | 322 | WeaponTextsC: The descriptions of SLAM Laser, Sleeper mine, Skeet bomb, Spectre, K-40 Mortar, Turret, Phantasm, K-90 Cluster |
| payload-line-text.txt | bank 6 `$D936-$D9B1` | 124 | PayloadLineText: Texts of the payload: "MAX PAYLOAD 1000KG", "PAYLOAD WGT 0KG", the two errors, the weight |
| quit-text.txt | bank 6 `$DA5E-$DA8B` | 46 | QuitText: Text: "Are you sure you want to quit?" and "Yes/No." |
| status-legend-text.txt | bank 6 `$DAA1-$DAC0` | 32 | StatusLegendText: Text: the map's legend "Roads." and "Rivers." with their glyphs $80 and $81 |
| briefing-legend-text.txt | bank 6 `$DAE1-$DB00` | 32 | BriefingLegendText: Text: "Roads." and "Rivers." for the briefing map |
| options.txt | bank 6 `$F93F-$F9C2` | 132 | OptionsText: Text: "SELECT CONTROL SYSTEM." and the five devices |

The text is UTF-8: the characters `$20-$7E` as themselves, every other byte as `{XX}` (also `{` and `}`). A line
break is written before a control code that follows a character and ignored when the text is read back. PrintString's
bytes: below `$20` a control code (table ControlCodes `$6F8F`), `$20-$81` a character of Font8x8, `$82` and above a
token (a string from the word table `$9860`), `$FF` the end. The control codes and their operand bytes:

| Code | Operands | Routine |
| --- | --- | --- |
| 0 | column | CodeColumn `$6EA7` |
| 1 | row | CodeAt `$6EB3` |
| 2 | row, column | CodeAtColumn `$6EAE` |
| 3 | - | CodeNumberA `$6EFB`: three digits of the constant `$5E` (`LD A,$5E` overwrites A): "094"; no string uses it |
| 4 | - | CodeHex `$6F17`: two hex digits of the constant `$5E`: "5E"; no string uses it |
| 5 | column | CodeSmallChars `$6DA6`: the small font's column in 6-pixel cells; the font is not switched |
| 7 | - | CodeSmallFont `$6DA1` (then CodeAt) |
| 8 | address | CodeNumber `$6EF1`: the byte there as three digits |
| 9 | margin | CodeLeftMargin `$6F79` |
| 10 | - | SmallNewLine `$6F67` |
| 11 | - | CodeNewLine `$6F4D` |
| 12 | - | CodeMarginHere `$6F80` |
| 13 | attribute | CodeInk `$6F88` |

The other codes: ControlCodes `$6F8F` in src/game (18 words, 4 of them zero).

Every text of bank 6 is a resource: the build reads the `.bin` that res_formats.py writes from the `.txt`. A text
with a label inside it (a digit field, a second message) is one file over several INCBIN slices, so the labels stay
where the code reads them. The operand of code 8 is an address and stays a number in the text (StatusText,
FinalScoreText): moving the digits means changing that number too. The failure reasons
(`$CCAB`, `$CCBE`, `$CCD8`, `$CCED`) are in bank 6, inside failed-texts.txt, not in bank 0.
