# 11. Data reference

Every data entry of the game image `$60F8`-`$FFFF`, in address order by module (`src/game/<module>.asm`):
tables, buffers, records, variables, graphics, text; an inner label (a field, a row) is a row of its own under
its entry, its size up to the next label; an entry with inner labels gives its own bytes, up to the first,
of the whole entry's ("17 of 34"). The name, the title and the description are the
source's (`src/game/game.ann`); the readers and writers are the routines the recordings saw touch it
(`work/game`, local and not in the repository), then those only the case's other recordings (`read_builds`) saw, with the first of them in brackets, and, marked
"(code)", the routines (the label at or below the instruction) whose `LD` through `(nn)`, or through `HL`, `DE` or `BC` loaded with `nn` in the same block, reads or writes it where the recordings did not see them do so.
Written by `kit/refdocs.py`.

## leftover

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$60F8` | `BuildLeftover` | 38 of 58 | Build leftover: 38 unidentified bytes, then a copy of the CODE header of the game block. Never read, written or executed (l1sum.py --reads 60F8-6131: no build reads a byte). The first 16 bytes (`$0F` `$E0` `$1F` `$E0` 0 ...) look like the first rows of TitleMoon `$6132`, the next 22 are not code that any path reaches. `$611E-$612E` is a 17-byte CODE header: type 3, the name "MOON" + `$AF` (the CODE token) + five spaces, length `$9F08` (the game block's 40712 bytes), start `$60F8`, parameter `$80F8`. The header on the tape (block 3) reads "MOON      " and parameter `$8000`, so this is a copy from the build, not the tape's. Stage 1 put the name at `$611D`; it is at `$611F`. | - | - |
| `$611E` | `LeftoverHeader` (`BuildLeftover`+38) | 20 | CODE header copy: type 3 | - | - |

## graphicsa

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$6132` | `TitleMoon` | 250 | The title logo's "Moon": 10 bytes x 25 lines, copied to x 88, lines 24-48. Copied by the copier `$AFAB` from the title `$8004` (`$8024`: BlitTop 24, BlitBottom 49, BlitX `$58` = byte 11, width 10) and at each life start from `$9136` (`$9163`, the HUD header). Linear rows of 10 bytes, one bit a pixel, set = ink; no mask, no shifts. All 250 bytes are read in every build (game, a1 twice, g1, t1, p2, h1 twice, i1, i2). | `BlitRows` | - |
| `$622C` | `TitlePatrol` | 350 | The title logo's "Patrol": 14 bytes x 25 lines, copied to x 72, lines 55-79. Copied by the copier `$AFAB` from `$8036` (BlitTop `$37`, BlitBottom `$50`, BlitX `$48`, width 14). Same format as TitleMoon `$6132`. The last 58 bytes, `$6350-$6389`, are also the first 3 1/4 shift slots of BuggyWreck1's frame: SpriteTable entry `$3C` points at `$6350`, so wreck piece 1 drawn at x AND 7 = 0-3 shows bytes of the logo (see BuggyWreck1 `$638A`). | `BlitRows`, `DrawSprite16x9`, `SpriteXor2Wide` (`runs/a1`) | - |
| `$638A` | `BuggyWreck1` | 86 | Wreck piece 1 of the buggy (sprite `$3C`): the visible part of its 2x9 frame, slots 3 1/4 to 7. Sprite `$3C`, drawer `$B02A`: 2 bytes x 9 lines, 8 shift slots of 18 bytes, one per pixel of x AND 7, from `$6350`. Its first 58 bytes, `$6350-$6389`, are the end of TitlePatrol `$622C`, so this entry starts where the piece's own bytes start: the middle of slot 3 (its line 2). Slots 4-7 (`$6398-$63DF`) hold a wheel with its hub on top, moving one pixel a slot. Drawn by the wreck routine `$AB37` (`$AB95`) after a death: the three pieces `$3C-$3E` fly from the buggy along the path at `$AC31`. Read in game, a1, g1, p2, h1, h2 (deaths), never in the immune runs i1 / i2. A piece that leaves the top of the screen is drawn with a line number past 191, so the line table read runs past ScreenLineTable `$FC00` into the print code at `$FD80` (reads of `$FDA6-$FDB7`, game / g1 / p2 / h1 / h2) and the XOR lands on `$6F75-$6F79`, `$77B5-$77B9`, `$7D15-$7D19` and `$CB5B-$CB5F`; every byte there is written an even number of times (draw and erase), so the image is restored. | `DrawSprite16x9`, `SpriteXor2Wide` (`runs/a1`) | - |
| `$63E0` | `BuggyWreck2` | 144 | Wreck piece 2 of the buggy (sprite `$3D`): 2x9, 8 shift slots of 18 bytes. Drawn by the wreck routine `$AB37` (`$ABD0`). A wheel with a stub; slots 0-2 move right, slot 3 restarts 5 pixels left (the image's origin moves with the slot). All 144 bytes read in game, a1, g1, p2, h1, h2. | `DrawSprite16x9`, `SpriteXor2Wide` (`runs/a1`) | - |
| `$6470` | `BuggyWreck3` | 144 | Wreck piece 3 of the buggy (sprite `$3E`): 2x9, 8 shift slots of 18 bytes. Drawn by the wreck routine `$AB37` (`$AC0B`). A smaller wheel. Only the even slots were read (72 of 144 bytes): the piece's x stays even in the recordings. | `DrawSprite16x9`, `SpriteXor2Wide` (`runs/a1`) | - |
| `$6500` | `BuggyExplosion` | 4096 | The buggy's explosion (sprites `$1F-$26`): 8 frames of 5x23 bytes, 4 shift slots of 128 bytes each. Drawer `$B1C8`: 5 bytes x 23 lines = 115 bytes at the start of each 128-byte slot (13 bytes of padding), slot = x AND 6 (2-pixel steps), 4 slots = 512 bytes a frame, frames at `$6500`, `$6700`, ..., `$7300`. Drawn by the buggy routine `$AA0F` (`$AABC`): sprite `$1E` + DeathStep `$B216` (1-8) at the buggy's place, one frame a pass; the main loop `$96CC` erases frame `$26` when DeathStep reaches 8. The tank's explosion, sprites `$33-$36`, reuses the first four frames (SpriteTable `$B3A2`). Slot 0 of frame 1 (`$6500-$6572`) is not an explosion: lines 0-11 and 20-22 hold other bytes (rows of 2-pixel stripes), lines 12-19 are blank. It is read in game, a1, g1, p2, h1, h2, so a buggy dying at an x with x AND 6 = 0 shows those stripes for one frame; how it looks is for a run to confirm. 3685 of the 4096 bytes are read. | `DrawSprite16x9`, `DrawSprite40x23`, `SpriteXor2Wide` (`runs/a1`) | `DrawSprite16x9`, `SpriteXor2Wide` (`runs/a1`) |
| `$7500` | `PlantScore` | 256 | The "500" sign shown where a green plant was shot (sprite `$73`): 4x16 bytes, 4 shift slots of 64. Drawer `$B184`: 4 bytes x 16 lines, slot = x AND 6, 256 bytes. Drawn by the plant routine at `$A415` (LD A,`$73`) after the plant is shot. Read only in i2 (Champion), slots 0 and 2 (128 of 256 bytes). | `DrawSprite16x9` (`runs/g1`) | - |
| `$7600` | `BurstLarge` | 768 | Large burst, 4 frames of 3x16 bytes (sprites `$2F-$32` with colour, `$60-$63` without). Drawers `$B115` (sprites `$2F-$32`, also colours 3x3 cells) and `$B10D` (`$60-$63`): 3 bytes x 16 lines, 4 slots of 48 bytes (x AND 6), 192 bytes a frame, frames at `$7600`, `$76C0`, `$7780`, `$7840`. `$60-$63` are the large boulder's break-up: the boulder handler sets its frame to `$5F` (`$A1FC`) and `$A29C` counts it up until (frame - `$5C`) AND `$D7` is 0, at `$64`. `$2F-$32` are a shot UFO's burst: the UFO handler counts its frame up and ends at `$33` (`$9CCA-$9CD4`). Read in i1 1920 and i2 8064 times, a few reads in the other builds. | `DrawSprite16x9`, `SpriteXor2Wide` (`runs/a1`) | `DrawSprite16x9`, `SpriteXor2Wide` (`runs/a1`) |
| `$7900` | `Debris` | 576 | Debris, 4 frames of 3x12 bytes (sprites `$2B-$2E`, `$5C-$5F` and `$7B-$7E`). Drawer `$B0E2`: 3 bytes x 12 lines, 4 slots of 36 bytes (x AND 6), 144 bytes a frame, frames at `$7900`, `$7990`, `$7A20`, `$7AB0`. Sprites `$2B-$2E` are a shot rock's pieces (the rock handler counts its frame up to `$2E`, `$9A79` CP `$2F`); `$7B-$7E` a shot plant's (`$A439` CP `$7F`). `$5C-$5F` point here too, but the medium boulder's count stops at `$5B`: no user of `$5C-$5F` was found. Read in every build except t1. | `DrawSprite16x9`, `DrawSprite24x12`, `SpriteXor2Wide` (`runs/a1`), `SpriteXor3Wide` (`runs/a1`) | `DrawSprite16x9`, `SpriteXor2Wide` (`runs/a1`) |
| `$7B40` | `BurstMedium` | 576 | Medium burst, 4 frames of 3x12 bytes (sprites `$58-$5B`). Drawer `$B0E2` (as Debris `$7900`), frames at `$7B40`, `$7BD0`, `$7C60`, `$7CF0`. The medium boulder's break-up: the boulder handler sets its frame to `$57` (`$A1F3`) and `$A29C` counts `$58-$5B`. Read in i2 2880 times; the few reads in game, a1, g1, p2, h1, h2 (`$7D15-$7D19`) are the wreck pieces' stray XOR (BuggyWreck1 `$638A`). | `DrawSprite16x9`, `SpriteXor2Wide` (`runs/a1`) | `DrawSprite16x9`, `SpriteXor2Wide` (`runs/a1`) |
| `$7D80` | `BurstSmall` | 384 | Small burst, 4 frames of 3x8 bytes with colour (sprites `$27-$2A` and `$37-$3A`). Drawer `$B069`: 3 bytes x 8 lines, 4 slots of 24 bytes (x AND 6), 96 bytes a frame, frames at `$7D80`, `$7DE0`, `$7E40`, `$7EA0`; the drawer also colours 3x2 cells with the colour in E'. `$37-$3A` are the low flyer's explosion (its handler counts to `$3A`, `$A160` CP `$3B`); `$27-$2A` a UFO's smaller burst, ended at `$2B` by the same count (`$9CCD`). Read only in i1 (6144) and i2 (4416). | - | - |
| `$7F00` | `BuildDate0335` | 20 | A print string with the build date 03:35 30/10/84, printed at each life start; its first byte `$1F` ends it at once. The life start `$90D3` prints it (`$911A` LD HL,`$7F00`; CALL `$FFD0`) and PrintText `$FFD0` stops at the first byte, `$1F`: nothing is printed. Read once per life start (game 20, a1 4, g1 4, p2 8, h1 4, i1 6, i2 6); `$7F01-$7F13` are never read. The rest reads as a whole print string: x 0, line `$19`, FONT 2, "03:35 30/10/84", end (`$1F`). With `$16` (AT) instead of the first `$1F` it would print the date at x 0, line 25. The three other dates are disabled the same way: `$90B8` (line `$21`), `$A182` (line `$29`) and BuildDate0245 `$B2C2` (line `$31`), printed one after the other by `$90D3`. | `PrintText` | - |

## interrupt

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$7FBF` | `CopyrightLeftover` | 38 | Leftover: "c 1984 Atari Inc. All Rights Reserved" with a 0 after it, never read. No build reads `$7FBF-$7FFF` (l1sum.py --reads 7FBF-7FFF: no reads in game, a1, g1, t1, p2, h1, i1, i2, h2) and no operand in the image points at it. The text the title prints is TitleText `$8413`. | - | - |
| `$7FE5` | `CopyrightPadding` | 27 | Leftover: 27 zero bytes up to `$7FFF`, never read | - | - |

## menus

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$83BA` | `OptionPlayerKeys` | 6 | The players group of the options page: key value, option value, pixel row (O = 1 at `$21`, T = 2 at `$29`). Read by OptionsPage `$80D7` through OptionsSelect (a1 958 reads of `$83BA`). The key values are KEY_SCAN's (`$1A` = O, `$05` = T); the row is the line's pixel row in OptionsText. | `OptionsFindEntry`, `OptionsSelect` | - |
| `$83C0` | `OptionCourseKeys` | 6 | The course group: 1 = Beginner (key value `$24`, row `$39`), 2 = Champion (`$1C`, row `$41`) | `OptionsFindEntry`, `OptionsSelect` | - |
| `$83C6` | `OptionControlKeys` | 18 | The controls group: Z X C V B K (`$1F` `$17` `$0F` `$07` `$00` `$11`) = 1-6, rows `$51-$79`. The values stored in `$B259`: 1 Sinclair with 1 joystick, 2 Kempston, 3 Cursor, 4 Old-type Fuller Box, 5 Sinclair with 2 joysticks, 6 Keyboard (OptionsText). a1 827 reads. | `OptionsFindEntry`, `OptionsSelect` | - |
| `$83D8` | `ScoreTableSprites` | 48 | The sixteen sprites of the score advance table: y, x, sprite number for `$A826`. Read by ScoreAdvancePage `$814F`: a1 20 times, t1 once. | `OptionsPage` (`runs/a1`) | - |
| `$8408` | `ColourCycle` | 11 | The menu colour cycle: each attribute found in the first ten bytes becomes the one after it (`$44` `$04` `$46` `$06` `$42` `$41` `$43` `$03` `$05` `$45`, back to `$44`). Read by CycleScreenColours and CycleColourRange (CPIR over ten bytes, the eleventh byte closes the loop). a1 1 793 645 reads. | `CycleColourRange`, `CycleScreenColours` | - |
| `$8413` | `TitleText` | 231 | The title page text: the copyright line, "Press S to start." and the key list. Printed by TitlePage `$803C` (`$FFD0`). Every build read it once a title (a1 2). A print string: codes in the notes; the first glyph "C" stands for the copyright sign in the title's look. | `PrintText` | - |
| `$84FA` | `OptionsText` | 347 | The options page text: SELECT OPTIONS, the players, the courses, the six controls, the keys. Printed by OptionsPage `$806E`: a1 21 times. The control lines name the choices of `$B259` in order 1-6; the keyboard line adds "A=Slow, Q=Fast, O=Jump, p=Fire". | `DrawSprite16x9`, `PrintText`, `SpriteXor2Wide` (`runs/a1`) | `DrawSprite16x9`, `SpriteXor2Wide` (`runs/a1`) |
| `$8655` | `ScoreAdvanceText` | 177 | The score advance table's text: the title, the underline and the points of each enemy (shot / jumped). Printed by ScoreAdvancePage `$815C`: a1 20, t1 1. The "???" is the game's own: the low flyer's points for a shot (stage 1 table). | `PrintText` | - |
| `$8706` | `DemoText` | 16 | "DEMO" in font 1, then font 2 selected. Printed by DemoPage `$81A1`: a1 once. | `PrintText` | - |
| `$8716` | `TapeErrorText` | 37 | "Tape error - hit any key.": printed by TapeFailed when a load or verify fails, never read. Selected at `$82C2` for any failed LD_BYTES whose last byte read was not `$6B`. Not read in any recording (game, a1, g1, t1, p2, h1, i1, i2, h2): known only from the code. | `PrintText` | - |
| `$873B` | `RobotronWarningText` | 113 | "WARNING- You have attempted to load an Atarisoft Robotron hi-score table. Please try again!!!", never read. Selected at `$82BB` when the failed block's flag byte was `$6B`. Not read in any recording (game, a1, g1, t1, p2, h1, i1, i2, h2): known only from the code. | `PrintText` | - |
| `$883D` | `FrameColourPairs` | 16 | The frame's eight colour pairs (outer ring, inner ring): each inner colour is the next pair's outer one. Read by CycleFrameColours (a1 270 reads of `$883D`). | `CycleFrameColours`, `PrintText` | - |

## hiscores

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$8866` | `HeroesTable` | 70 | The heroes: ten records of three initials and a four-byte BCD score, best first (MIK 1200 ... PJS 120 in the image). Drawn by HeroesDrawTables; the tenth score `$88A8` is HiScoreEntry's threshold, and records shift down from the insert place (HeroesInsert). Not part of the tape block. h1 put MPA (score 1260) at the top. | `HeroesPrintRow`, `HiScoreEntry`, `PrintBcd`, `PrintText`, `ScoreCompare` | `HiScoreEntry` |
| `$88AC` | `GreatestPoint` | 1 | THE GREATEST's course point (1-25, A-Z without O): `$18` = Y. The first byte of the tape block `$88AC-$89D9`. Written by GreatestEntry from `$B27C`; the HUD prints it after the hi-score (`$91DD` with `$9258`). Read in every build that drew the HUD (i1 12 reads). | `HudDraw`, `PrintText` | `GreatestEntry` (code) |
| `$88AD` | `GreatestName` | 21 | THE GREATEST's name, 20 letters (SPIKE NOTWELL), ended by `$1F` for `$FFD0`. Printed by HeroesDrawTables; GreatestEntry edits it in place (h2 typed STAGE ONE over SPIKE NOTWELL: the untyped tail stays, "STAGE ONEWELL"). | `PrintText` | - |
| `$88C2` | `GreatestScore` | 4 | THE GREATEST's score, BCD (00 05 00 00 = 50000): the hi-score of the HUD. Read by the HUD (`$91DD`), HeroesDrawTables and HiScoreEntry (the GreatestEntry test). i1 24 reads. | `PrintBcd`, `PrintText`, `ScoreCompare` | - |
| `$88C6` | `GreatestInitials` | 3 | THE GREATEST's initials (JAS) | `HeroesDrawTables`, `PrintText` | - |
| `$88C9` | `AllTimeTable` | 273 | The all-time heroes 2-40: 39 records of initials and BCD score, best first; the last score `$89D6` is HiScoreEntry's first threshold. h1 put MPA at 40 (the last record, `$89D3`). GreatestEntry shifts the whole table down and makes the old greatest number 2. | `AllTimePrintRow`, `PrintBcd`, `PrintText`, `ScoreCompare` | `HiScoreEntry` (`runs/h1`) |
| `$89DA` | `HeroesTitleText` | 36 | "MOON PATROL HEROES". Printed by HeroesDrawTables `$8AE0` (a1 2, h1 1, game 4). | `PrintText` | - |
| `$89FE` | `AllTimeTitleText` | 33 | "ALL TIME HEROES" and "1) " for THE GREATEST | `PrintText` | - |
| `$8A1F` | `HeroesTapeKeysText` | 45 | "L=LOAD, J=SAVE, G=VERIFY HI-SCORES." at the foot of the page | `PrintText` | - |
| `$8D4E` | `InitialsField` | 5 | Entry field descriptor (length, buffer, y, x): 3 letters into `$B289` at y `$7C`, x `$77`. Copied to `$B24B` before EntryFieldEdit by HiScoreEntry `$8C03` (read in game, g1, p2, h1). The three descriptors InitialsField, GreatestNameField, GreatestInitialsField have one layout: length, the buffer address, y, x. | `HiScoreEntry` | - |
| `$8D53` | `GreatestNameField` | 5 | Entry field descriptor: THE GREATEST's 20 letters at `$88AD`, y `$7C`, x `$44`. Used by GreatestEntry `$8E96` (h2). | - | - |
| `$8D58` | `GreatestInitialsField` | 5 | Entry field descriptor: the initials after the name, 3 letters into `$B289` at y `$A0`, x `$77`. Used by GreatestEntry `$8EB6` (h2). | - | - |
| `$8DB1` | `HiScoreTexts` | 5 of 157 | The texts of the hi-score entry, printed in pieces; first INK 6 BRIGHT 1, printed after the player number. All printed by HiScoreEntry and GreatestEntry with `$FFD0`; the pieces are reused ("3" + the tail of "20 LETTERS MAXIMUM", "YOU ARE " without its AT for THE GREATEST, "PLEASE ENTER YOUR " again after the name). CongratulationsText `$8DB6`: "CONGRATULATIONS PLAYER " (the player digit follows) YouAreText `$8DDE`: "YOU ARE " without the AT (THE GREATEST) AnAtariHeroText `$8DF4`: "AN ATARI MP HERO", AT, "PLEASE ENTER YOUR " AtariHeroText `$8DF6`: " ATARI MP HERO" and the rest (after THE GREATEST) PleaseEnterText `$8E07`: "PLEASE ENTER YOUR " without the AT (after the name) LettersAtText `$8E27`: AT, INK 5 for the letters line LettersMaximumText `$8E2F`: " LETTERS MAXIMUM" (after a "3") GreatestAtText `$8E40`: AT for "YOU ARE THE GREATEST" InitialsAtText `$8E44`: AT for the initials prompt after the name | `PrintText` | - |
| `$8DB6` | `CongratulationsText` (`HiScoreTexts`+5) | 37 | - | `PrintText` | - |
| `$8DDB` | `YouAreAtText` (`HiScoreTexts`+42) | 3 | AT, then "YOU ARE " | `PrintText` | - |
| `$8DDE` | `YouAreText` (`HiScoreTexts`+45) | 9 | - | `PrintText` | - |
| `$8DE7` | `TheGreatestText` (`HiScoreTexts`+54) | 13 | "THE GREATEST" | `PrintText` | - |
| `$8DF4` | `AnAtariHeroText` (`HiScoreTexts`+67) | 2 | - | `PrintText` | - |
| `$8DF6` | `AtariHeroText` (`HiScoreTexts`+69) | 17 | - | `PrintText` | - |
| `$8E07` | `PleaseEnterText` (`HiScoreTexts`+86) | 19 | - | `PrintText` | - |
| `$8E1A` | `InitialsText` (`HiScoreTexts`+105) | 9 | "INITIALS" | `PrintText` | - |
| `$8E23` | `NameText` (`HiScoreTexts`+114) | 4 | "NAME", then AT, INK 5 | `PrintText` | - |
| `$8E27` | `LettersAtText` (`HiScoreTexts`+118) | 6 | - | `PrintText` | - |
| `$8E2D` | `TwentyLettersText` (`HiScoreTexts`+124) | 2 | "20 LETTERS MAXIMUM" | `PrintText` | - |
| `$8E2F` | `LettersMaximumText` (`HiScoreTexts`+126) | 17 | - | `PrintText` | - |
| `$8E40` | `GreatestAtText` (`HiScoreTexts`+143) | 4 | - | `PrintText` (`runs/h1`) | - |
| `$8E44` | `InitialsAtText` (`HiScoreTexts`+147) | 10 | - | `PrintText` (`runs/h1`) | - |

## gamestart

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$9073` | `TextPlayer` | 19 | Print string (PrintText `$FFD0`): white on black, AT x `$68` y `$55`, font 1, "PLAYER " (the digit follows). The print codes of `$FDCC` that these strings use: `$10` n ink, `$11` n paper, `$13` n bright, `$16` x y a position in pixels, `$18`, `$19`, `$1A` n the font; `$1F` ends the string (PrintText `$FFD0` stops on it). Printed by GameStartLife `$8F7A`: read game 20, a1 3, g1 4, p2 8, h1 4, i1 1, i2 1 (one read a life). | `PrintText` | - |
| `$9086` | `TextGameOver` | 21 | Print string: AT x `$65` y `$55`, font 1, "GAME OVER" (one player). Printed by GameAfterLife `$8FCD`: read game 4, g1 1, h1 1, h2 1. | `PrintText` | - |
| `$909B` | `TextGameOverPlayer` | 29 | Print string: AT x `$4B` y `$55`, font 1, "GAME OVER PLAYER " (the digit follows). Printed by GameAfterLife `$8FE5`: read p2 2. | `PrintText` | - |
| `$90B8` | `TextNoDate` | 1 | An empty print string (`$1F` only): LifeStart prints it, and the build stamp after it is never printed. LifeStart `$9123` prints from here at every life start (read game 20, a1 4, g1 4, p2 8, h1 4, i1 6, i2 6). The `$1F` ends the string at once, so the stamp BuildStamp `$90B9` that follows is never read (no reads in any recording). LifeStart prints three more strings of this shape: `$7F00`, `$A182`, `$B2C2`, each a `$1F` before a stamp. | `PrintText` | - |
| `$90B9` | `BuildStamp` | 19 | A build time stamp, never printed: `$00` `$21`, font 2, "20:15 29/10/84", `$1F`. Not read in any recording (game, a1, g1, t1, p2, h1, i1, i2, h2): known only from the bytes. The other stamps: `$7F01` "03:35 30/10/84", `$A183` "03:40 30/10/84", `$B2C3` "02:45 29/10/84". | - | - |
| `$93D3` | `HudTextLamps` | 33 | Print string: ink 1 paper 1, AT x `$E0` y 2 "DANGER!", AT x `$E0` y `$0A` "CAUTION" (the lamp texts). Printed by HudDraw `$9180` in blue on blue: HudLamps colours them. game 21 reads. | `PrintText` | - |
| `$93F4` | `HudText1P` | 5 | Print string: font 2, "1P" (HudDraw puts the position first) | `PrintText` | - |
| `$93F9` | `HudText2P` | 6 | Print string: AT x 2 y `$11`, "2P" (two players only: p2 9 reads) | `PrintText` | - |
| `$93FF` | `HudTextTimePoint` | 16 | Print string: AT x `$9B` y 1 "TIME", AT x `$9E` y 9 "POINT" | `PrintText` | - |
| `$940F` | `HudTextBeginner` | 12 | Print string: AT x `$9B` y `$11` "BEGINNER" (game 21 reads) | `PrintText` | - |
| `$941B` | `HudTextChampion` | 12 | Print string: AT x `$9B` y `$11` "CHAMPION" (read i1 1: the Champion course after Z; i2 11) | `PrintText` | - |
| `$9427` | `HudTextPointAt` | 6 | Print string: AT x `$C2` y 9, font 2 (the point letter follows: HudPrintPoint) | `PrintText` | - |
| `$942D` | `HudLampColours` | 60 | The warning lamp attributes: 4 patterns (`$B27E` 0-3) of 3 rows x 5 cells (the lamp, then the text). Read by HudLamps `$927E`: pattern = `$942D` + 15 x `$B27E`. Column 27 the lamp glyph, columns 28-31 the text. `$08` / `$09` unlit (black or blue ink on blue), `$0C` green, `$0E` yellow, `$0A` red, `$0F` white text. | `HudLamps` | - |
| `$9469` | `HudPlayerIcon` | 16 | A 16x8 icon drawn at the top left of the HUD (`$4000`) by HudDraw | `HudDraw` | - |
| `$9479` | `HudLampGlyph` | 8 | The lamp glyph (a round light), drawn in column 27 of rows 0-2 by HudDraw (game 63 reads) | `HudDraw` | - |
| `$9481` | `HudPanel` | 192 | The HUD panel: 24 lines of 8 bytes at x `$50`, rows 0-2: the four buggy icons, the course marks, the progress bar frame. Drawn by `$AFAB` from HudDraw. Lines 0-7: four 16x8 buggies (HudLives shows or hides each by its colour); lines 10-14: small marks over the bar; lines 16-21: the frame of the progress bar that HudProgress fills. game 21 reads. | `BlitRows` | - |
| `$9617` | `SceneryColourSets` | 10 | The two scenery colour sets, 5 attributes each: rows 3-7, 8-11, 12-15, 16-19, 20-23. Picked by SceneryColours from `$B27D`: 0 the mountains, `$FF` the city (`$B27D` comes from the sector-end record of the bonus screen `$A4EE`). The byte +1 is read every pass (SceneryColoursRepaint); +3 is read by other routines through `$B230` too (i2: 2094 reads of `$961A`). | `SceneryColours`, `SceneryColoursRepaint` | - |
| `$9621` | `HudAttributes` | 96 | The attributes of the HUD rows 0-2, copied to `$5800` by HudDraw | `HudDraw` | - |
| `$9681` | `ShotBoxes` | 21 | The shots' boxes, copied to `$5B60` at each life start: y, x, height, width of a flat 3x6 shot (+1 byte), then four 4x3 boxes. LifeStart copies these 21 bytes to the printer buffer `$5B60`. y = `$FF` means no shot. The rock handler ObjRock `$99C3` tests its box against the first one (the forward shot) with `$A7FE` and sets its x (`$5B62`) to `$FF` on a hit. The names forward / up shot are from the shapes and from the rock (a ground object) testing only the first box; the writers of these boxes and the users of the four 4-byte boxes (height 4, width 3) are outside this range. | `LifeStart` | - |

## course

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$9740` | `CourseBreakToBasic` | 5 | Never called: the bytes of CALL SetIm1 `$A7CB`, RST 8, DEFB `$14` (the report L BREAK into program). No reference to it in the image, never executed or read in any recording (game, a1, g1, t1, p2, h1, i1, i2, h2): known only from the bytes. Kept as data: as code the walk would run on into `$9744` (`$14` as INC D). With BreakKeyTest before it, it reads as a removed '0' = BREAK exit to BASIC (a JR NZ to here). | - | - |
| `$97A7` | `TextPointAt` | 6 | Print string: AT x `$F9` y `$B1`, font 2 (CmdPoint prints the point letter after it) | `PrintText` | - |

## enemies

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$A182` | `LifeStartDateText` | 20 | A print string for `$FFD0` that ends at its first byte: under it the build date 03:40 30/10/84, never printed. The life start prints it at `$9126` (LD HL,`$A182`, CALL `$FFD0`). `$FFD0` stops at `$1F`, the first byte, so nothing is printed: only `$A182` is read (game 20, a1 4, g1 4, p2 8, h1 4, i1 6, i2 6, once a life start); `$A183-$A195` are never read in any recording. A leftover of the build, like the date 03:35 30/10/84 at `$7F05` five minutes earlier. | `PrintText` | - |
| `$A4B2` | `PlantHitBoxes` | 60 | The green plant's hit box by frame 1-15: dy, dx, then two bytes the code loads and never uses. PlantHandler reads row frame - 1 into E, D, C, B; only E (dy) and D (dx) are used, as the box's offset and as its height and width. Bytes 3-4 look like the intended height and width (dy + byte 3 = 16 in every row, byte 4 the width), but C and B are overwritten by `$A7FE`: known only from the code. Read i2 28-40 times a row. | - | - |

## bonus

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$A6A0` | `BonusHeaderText` | 102 | The bonus screen's three labels: TIME TAKEN TO REACH POINT, TIME REQUIRED FOR BONUS, BEST TIME SO FAR. A string of the print routine `$FFD0`: `$16` x y moves to the pixel position x, y (`$16` `$1A` `$49` here), `$0D` starts the next line, `$1F` ends; `$18` and `$1A` take one byte each (their role is the print routine's). The numbers are printed after it by SectorBonus at x `$C2`. Read by SectorBonus `$A519` (i1 5, i2 5 reads a byte). | - | - |
| `$A706` | `SectorBonusText` | 19 | SECTOR BONUS = at x `$46`, y `$69` | - | - |
| `$A719` | `TimeBonusText` | 19 | TIME BONUS   = at x `$46`, y `$71` | - | - |
| `$A72C` | `NoTimeBonusText` | 23 | SORRY NO TIME BONUS at x `$46`, y `$71` (never read in the recordings) | - | - |
| `$A743` | `BestTimeText` | 48 | AWESOME! BEST SECTOR TIME SO FAR!! in its own colours (`$10` ink 4, `$11` paper 0, `$13` bright 1) at x `$1C`, y `$81` (never read in the recordings) | - | - |
| `$A773` | `BonusTune` | 88 | The sector-end fanfare: 22 notes of 4 bytes: BEEPER period (word), length (byte), a spare byte. Played by BonusTuneLoop `$A56B`: HL = the period, DE = the length byte; the fourth byte is never read (l1sum --reads `$A773-$A7CA`: three bytes of each four read 5 times in i1). Doc 2's "never touched `$A72C-$A7CA`" holds only for the two texts and these spare bytes. | - | - |

## play

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$A9AF` | `RoadFeed` | 32 of 96 | The road's feed strips: 32 bytes a strip, one a line of 160-191: plain road, then the crater's two walls. ScrollRoad copies the strip at `$B232` to FeedRoad every 2 passes. The life start (`$90D3`) and the crater handler (`$9A92`, x = `$EC`) set the plain strip, the crater handler the wall strips as the crater comes in from the right (RoadFeedWallA or RoadFeedWallB). l1sum --reads: every byte read (game 667, i1 1727 times each). | `ScrollRoad` | - |
| `$A9CF` | `RoadFeedWallA` (`RoadFeed`+32) | 32 | a crater wall: `$FF` `$FF` `$7F` `$7F` `$3F` ... down to line 175, then nothing | `ScrollRoad` | - |
| `$A9EF` | `RoadFeedWallB` (`RoadFeed`+64) | 32 | the other wall: `$FF` `$FF` `$FE` `$FE` `$FC` ... down to line 175, then nothing | `ScrollRoad` | - |
| `$AAF0` | `JumpArcs` | 13 of 71 | The three jump arcs: y steps a pass, `$80` ends; back position (short), centre, forward (long). SpeedGovernor sets `$B221` to one of them from the buggy's x (JumpSpeeds `$AF68`), BuggyUpdate adds a byte a pass. The sums are 0: the buggy lands where it took off. l1sum --reads: all 71 bytes read. | `BuggyUpdate` | - |
| `$AAFD` | `JumpArcCentre` (`JumpArcs`+13) | 25 | x = `$38`: 24 steps, 19 pixels up | `BuggyUpdate` | - |
| `$AB16` | `JumpArcForward` (`JumpArcs`+38) | 33 | x > `$38`: 32 steps, 20 pixels up | `BuggyUpdate` | - |
| `$AC31` | `WheelPaths` | 192 | The wheels' paths: 32 steps of y up, x for the left, middle and right wheel. Read by WheelsFly. The y steps (up positive) fall from 11 or 12 to -7 (the outer wheels) or -2 (the middle one): arcs; x steps -3, 0, +4. l1sum --reads: read in game, a1, g1, p2, h1, h2 (the deaths). | `WheelsFly` | - |
| `$AE2E` | `ControlHandlers` | 12 | The six control readers by `$B259` - 1, in the options page's order Z X C V B K. Read by ControlsRead (l1sum --reads: `$AE38` a1 28 753, g1 922, ... i1 7202: the keyboard; `$AE2E` game 2296, `$AE30` game 643: c1's random keys chose Sinclair and Kempston; every word a1 7-8: the options page). | `ControlsRead` | - |
| `$AF68` | `JumpSpeeds` | 12 | Three records by the buggy's position: jump arc, delay count. l1sum --reads: forward `$AF68` i1 7056 of 7200 (the immune runs held fast), centre `$AF6C` game 2663, back `$AF70` game 228 only. | `SpeedGovernor` | - |

## variables

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$B212` | `BuggyY` | 1 | The buggy's pixel line (top of its sprite), `$92` at each life start. Set with BuggyX at the life start (`$90EB` LD HL,`$3892`; `$90EE`: y `$92`, x `$38`) and by the jump in the buggy routine at `$AA0F` (`$AA46`, `$AA79`); read as a pair with BuggyX by the main loop (`$96C5`), by the shots (`$AD0E`) and by every object handler that tests a hit against the buggy (`$99F0`, `$9E1F`, `$9EEA`, `$9FCA`, `$A0BB`, `$A1C4`, `$A34C`). | `BoxOverlap`, `BuggyAirborne`, `BuggyErase`, `BuggyUpdate`, `FireShots` +3 | `BuggyUpdate`, `LifeStart` |
| `$B213` | `BuggyX` | 1 | The buggy's x in pixels (left edge), `$38` at each life start. Read by the object handlers to place or aim at the buggy (`$9A2F`, `$9ACA`, `$9B27`, `$9F29`, `$9FF7`, `$A10E`). | `BoxOverlap`, `BuggyErase`, `BuggyUpdate`, `FireShots`, `MainLoop` +11 | `BuggyUpdate`, `LifeStart` |
| `$B214` | `BuggyBoxHeight` | 1 | The buggy's collision box height, `$0D`. Read with BuggyBoxWidth by the box test at `$A7FE`; never written. | `BoxOverlap` | - |
| `$B215` | `BuggyBoxWidth` | 1 | The buggy's collision box width, `$1D`. Read by the box test at `$A7FE`; never written. | `BoxOverlap` | - |
| `$B216` | `DeathStep` | 1 | `$FF` while the buggy lives; 0 when hit, then 1-8 through the explosion frames. Set to `$FF` at the life start (`$90E5`), to 0 by the routine at `$A7DD` (a hit). The buggy routine at `$AA0F` counts it up and draws sprite `$1E` + DeathStep; the main loop (`$96BE`) ends the life when it reaches 8. Every hazard handler reads it to stop hitting a dead buggy (`$99DE`, `$9A61`, `$9A9B` ...). | `BuggyErase`, `BuggyKill`, `BuggyUpdate`, `FireShots`, `MainLoop` +23 | `BuggyKill`, `BuggyUpdate`, `LifeStart`, `MainLoop`, `MainLoopPass` (code) |
| `$B217` | `WreckStep` | 1 | The wreck pieces' step after a death. Set to `$FF` at the life start (`$90E8`), set at a hit (`$A7E5`) and by the main loop (`$96D6`); counted by the wreck routine at `$AB37` (`$AB3C`, `$AC18`, `$AC1C`). | `WheelErase`, `WheelsFly` | `BuggyKill`, `LifeStart`, `MainLoop`, `WheelsFly`, `MainLoopPass` (code) |
| `$B218` | `WreckPath` | 2 | Pointer into the wreck pieces' flight path at `$AC31`. Set at `$AB5C`, read through IX at `$AB5F`, moved on at `$AC14`. | `WheelsFly` | `WheelsFly` |
| `$B21A` | `WreckPiece1` | 2 | Wreck piece 1's position (low byte y, high byte x). Set at `$AB4A`, read and moved at `$AB63-$AB92` by the wreck routine at `$AB37`. | `WheelsFly` | `WheelsFly` |
| `$B21C` | `WreckPiece2` | 2 | Wreck piece 2's position. `$AB50`, `$AB9E-$ABCD`. | `WheelsFly` | `WheelsFly` |
| `$B21E` | `WreckPiece3` | 2 | Wreck piece 3's position. `$AB56`, `$ABD9-$AC08`. | `WheelsFly` | `WheelsFly` |
| `$B220` | `DeadFlag` | 1 | `$FF` after a crater fall until the next life start, 0 otherwise. Set only by the crater fall at `$AAA1` (the shots use it to tell a crater death from an object kill), cleared at the life start (`$90F7`). While 0 the shots move with the ground (`$AD72`, `$ADC3` read it). | `ShotForwardMove`, `ShotUpMove` | `BuggyUpdate`, `LifeStart` |
| `$B221` | `JumpArc` | 2 | Pointer into the jump arc table at `$AF68` during a jump. Set at `$AF5E` when the jump starts; read each pass by `$AA2E`. | `BuggyUpdate` | `SpeedGovernor` |
| `$B223` | `JumpStep` | 1 | The jump's step, `$FF` on the ground. Set at the life start (`$90E2`); read and written by the buggy routine at `$AA0F` (`$AA1F-$AA49`). | `BuggyUpdate` | `BuggyUpdate`, `LifeStart` |
| `$B224` | `FarCountdown` | 1 | Passes left to the next column fed into FeedFarBand (the far band rolls 1 pixel every pass). Set at `$9568` and `$A873`, counted at `$A84B` by the far-band scroller at `$A846` (a new column every 8 passes). | `ScrollFarBand` | `ScenerySetup`, `ScrollFarBand` |
| `$B225` | `HillsSpeed` | 1 | The far band's (HillsStrip's) step, 1; never written. Read by `$AF82` (the shots' drift). | `ScrollAdjustX` | - |
| `$B226` | `FarColumn` | 2 | Pointer to the next column of HillsStrip `$EBC0` to feed in. Set at `$956E`; read and moved by the scroller at `$A851`/`$A865`, wrapping from `$F000` to `$EBC0`. | `ScrollFarBand` | `ScenerySetup`, `ScrollFarBand` |
| `$B228` | `MiddleCountdown` | 1 | Passes left to the next 2-pixel scroll of the middle layer (mountains or city). Set at `$9565` and `$A8C8`, counted at `$A89F` by the scroller at `$A89A` (one scroll every 4 passes). | `ScrollMiddleBand` | `ScenerySetup`, `ScrollMiddleBand` |
| `$B229` | `MiddleSpeed` | 1 | The middle layer's step, 2; never written. Read by `$AF8B` and `$AFA0`. | `ScrollAdjustX` | - |
| `$B22A` | `MiddleColumn` | 2 | Pointer to the next column of the middle strip to feed in. Set at `$9561`; read and moved at `$A8A5`/`$A8BA`. | `ScrollMiddleBand` | `ScenerySetup`, `ScrollMiddleBand` |
| `$B22C` | `MiddleStart` | 2 | The middle strip's first column: MountainsStrip `$E340` or MoonBaseStrip `$E780`. Set by the routine at `$9541` (`$9559`) from the scenery byte; read at `$957A` and `$A8B7` (the wrap). | `ScenerySetup`, `ScrollMiddleBand` | `ScenerySetup` |
| `$B22E` | `MiddleEnd` | 2 | The middle strip's end, compared at `$A8AC`. Set at `$955D`. | `ScrollMiddleBand` | `ScenerySetup` |
| `$B230` | `ColourScheme` | 2 | Pointer to the scenery's colour set at `$9617` or `$961C`. Set by the routine at `$95B0` (`$95BC`); read through IX by `$95F2` and by the handlers that colour sprites (`$A053`, `$A12C`, `$A148`, `$A165` ...). | `SceneryColoursRepaint`, `SceneryColours` (`runs/t1`), `LowFlyerActive` (code), `LowFlyerDraw` (code), `LowFlyerExplodeHandler` (code) +3 | `SceneryColours` |
| `$B232` | `GroundProfile` | 2 | Pointer to the ground's current height profile. Set at the life start (`$9111`) and by the crater handler (`$9AB4`, `$9AC5`); read by the ground scroller at `$A93D`. | `ScrollRoad` | `LifeStart`, `ObjCrater` |
| `$B234` | `GroundCountdown` | 1 | The ground scroller's pass counter. Set at `$90FA`; read and written at `$A937`/`$A94B`. | `ScrollRoad` | `LifeStart`, `ScrollRoad` |
| `$B235` | `GroundSpeed` | 1 | The ground's step in pixels a pass, 4; never written. Read by every handler that moves an object with the ground (`$99E4`, `$9A67`, `$9AA2`, `$9B1E`, `$9EDE`, `$9F71` ...). | `ObjCrater`, `ObjRock`, `ObjRockExplode`, `BoulderExplodeScroll` (code), `BoulderScroll` (code) +8 | - |
| `$B236` | `UfoWave` | 1 | The UFO wave's state, set by the UFO commands and by the UFO handler. Written at `$9833` and `$9B84`; read at `$9862`, `$987F`, `$9C0E`, `$9C52` ... | `CmdUfos`, `UfoBombDrop` (code), `UfoBombShot` (code), `UfoBombStep` (code), `UfoShot` (code) +1 | `CmdUfos`, `UfoBombKindSet` (code), `UfoKindSet` (code) |
| `$B237` | `UfosLeave` | 1 | `$FF`: the UFOs fly off (the course command at `$98AA`); 0 at the life start. Set at `$90F4`, `$9B99` and `$9EAF`; read by the UFO handler at `$9BE6`. | `UfoStep` (code) | `LifeStart`, `UfoKindSet` (code), `UfoRetreatStart` (code) |
| `$B238` | `ObjectsOff` | 1 | Nonzero: the main loop does not run the object list. Set at `$819E` (the demo's start, `$80`) and `$969B`; read by `$9745`. | `ObjectListRun` | `MainLoop`, `OptionsPage` (`runs/a1`), `DemoPage` (code) |
| `$B239` | `TimeShown` | 1 | Nonzero once this second's time is on screen; cleared each second. Cleared by the interrupt routine at `$7FAE` when FrameCount reaches 50; set at `$9223` after the time is printed; tested at `$922A`. | `HudPrintTime` | `HudDraw`, `HudPrintTime`, `Im2Clock` |
| `$B23A` | `TapeKey` | 1 | The key read by the tape menu at `$8282`, tested at `$8309` | `TapeLoadDone` (code) | `MenuCheckTape` (`runs/t1`) |
| `$B23B` | `PassCount` | 1 | A pass counter; its bit 2 blinks the mines. Incremented by the main loop (`$96E3`); read by the mine handler (`$9B42`): sprite `$11` + bit 2. | `MainLoop`, `MainLoopTimer` (code), `ObjMineDraw` (code) | `MainLoop`, `MainLoopTimer` (code) |
| `$B23C` | `SegmentWait` | 2 | Passes left before the course script runs its next segment. Set by the script command at `$976C` (`$9770`); counted down by the main loop (`$96E7`/`$96EB`). | `MainLoop`, `MainLoopTimer` (code) | `MainLoop`, `SegmentLength`, `MainLoopTimer` (code) |
| `$B23E` | `TunePointer` | 2 | The next word of Tune `$B4E6`. Set at the life start (`$9117`); read and moved by the interrupt routine (`$7F52`, `$7F60`), reset to the start at `$FFFF` (`$7F70`). | `TunePlayer` | `LifeStart`, `TunePlayer` |
| `$B240` | `TuneDivider` | 1 | Interrupts left before the next note (one note every 3). Set at `$90FD`; counted at `$7F47` and `$7FA1`. | `Im2Clock`, `TunePlayer` | `LifeStart`, `TunePlayer` |
| `$B241` | `SectorTime` | 2 | The sector's par time, a big-endian BCD word of seconds (`$0120` = 120 s; the clock never wraps at 60), from the SectorEnd command. Set at `$A4F2`; read at `$A531` and `$A584`. | `BonusWait1` (code) | `SectorBonus` (code) |
| `$B243` | `BestTime` | 2 | The sector's best time so far (BCD), from the SectorEnd command. Set at `$A507`; read at `$A53D`, `$A632`, `$A64A`. | `BestTimeCheck` (code) | `SectorBonus` (code) |
| `$B245` | `SectorBonusPoints` | 2 | The sector's bonus points (BCD hundreds) and the extra byte after it. Set at `$A4FA`; read at `$A54F`, `$A55B`, `$A5D0`; rewritten at `$A5B6`. `$A5BA` reads its second byte (`$B246`). | `SectorBonus` (code), `TimeBonusLoop` (code) | `BonusWait2` (code), `SectorBonus` (code), `TimeBonusLoop` (code) |
| `$B247` | `BlitTop` | 1 | The copier `$AFAB`'s first line. Set as a pair with BlitBottom (`$801B`, `$802D`, `$9157`); read at `$AFAB`. | `BlitRows` | `HudDraw`, `MenuEntry`, `TitlePage` (`runs/a1`) |
| `$B248` | `BlitBottom` | 1 | The copier's line after the last; read at `$AFD5` | `BlitRows` | `HudDraw`, `MenuEntry`, `TitlePage` (`runs/a1`) |
| `$B249` | `BlitX` | 1 | The copier's x in pixels (the byte column is BlitX / 8). Set with BlitWidth (`$8021`, `$8033`, `$915D`); read at `$AFB4`. | `BlitRows` | `HudDraw`, `MenuEntry`, `TitlePage` (`runs/a1`) |
| `$B24A` | `BlitWidth` | 1 | The copier's width in bytes; read at `$AFCD` | `BlitRows` | `HudDraw`, `MenuEntry`, `TitlePage` (`runs/a1`) |
| `$B24B` | `EntryLength` | 1 | The initials entry field: number of characters. The field `$B24B-$B24F` is filled from a 5-byte block by `$8C06` / `$8E99` / `$8EB9` (LD DE,`$B24B`; LDIR) and read at `$8CD0`, `$8D6F`, `$8D8A`. | `EntryFieldDraw`, `EntryFieldEdit` (`runs/g1`), `EditCursorRight` (code), `EditDelete` (code) | `HiScoreEntry` |
| `$B24C` | `EntryBuffer` | 2 | The entry field's buffer pointer; read at `$8CDA`, `$8D82`, `$8D87`, `$8DAC` | `EntryFieldDraw`, `EditCursorAddress` (`runs/g1`), `EditDelete` (code) | `HiScoreEntry` |
| `$B24E` | `EntryY` | 1 | The entry field's pixel line; read at `$8C9C`, `$8CCA` | `EntryFieldClear`, `EntryFieldDraw` | `HiScoreEntry` |
| `$B24F` | `EntryX` | 1 | The entry field's x; read at `$8CC4` | `EntryFieldDraw` | `HiScoreEntry` |
| `$B250` | `HeroSlot` | 2 | Pointer to the heroes table slot being written. Set at `$8C2E`, `$8C71`, `$8EE7`; read at `$8C44`, `$8C87`, `$8EEF`. | `HiScoreEntry`, `HiScoreFindSlot` | `HiScoreEntry`, `HiScoreFindSlot` |
| `$B252` | `HeroCount` | 1 | Heroes table work byte; with HeroIndex it is saved as a word. `$8EE3` LD (`$B252`),DE and `$8EFB` LD DE,(`$B252`) keep DE here across the slot search loop `$8EEA-$8EFF`; `$8CD3` reads it through HL. | `EntryFieldDraw`, `HiScoreFindSlot` | `EntryFieldDraw`, `HiScoreFindSlot` |
| `$B253` | `HeroIndex` | 1 | The heroes table's index; read at `$8CDE`, `$8D03` | `EntryFieldDraw`, `HiScoreFindSlot` | `EntryFieldDraw`, `HiScoreFindSlot` |
| `$B254` | `EntryCursor` | 1 | The entry field's cursor position. Read and written at `$8CE1-$8D76`. | `EntryFieldDraw`, `EditCursorAddress` (`runs/g1`), `EntryFieldEdit` (`runs/g1`), `EditCursorLeft` (code), `EditCursorRight` (code) +1 | `EntryFieldEdit`, `EditCursorLeft` (code), `EditCursorRight` (code) |
| `$B255` | `TitleColour` | 1 | The title frame's colour step, read and moved at `$884D`/`$8853` | `CycleFrameColours` | `CycleFrameColours` |
| `$B256` | `TableRow` | 1 | The score advance table's row. `$8A52`, `$8A9C`, `$8AEF`, `$8B07`, `$8B50`, `$8B63`. | `PrintBcd` | `HeroesDrawTables` |
| `$B257` | `Players` | 1 | Number of players, 1 or 2. Set by the options page (`$80DF`); read at `$8083`, `$80D3`, `$8F61`, `$8F8B`, `$8FB3` ... | `GameStart`, `HudDraw`, `HudPrintScore`, `OptionsPage`, `JoySinclair2` (`runs/a1`) +3 | `OptionsPage` |
| `$B258` | `Course` | 1 | The course: 1 Beginner, 2 Champion. Set at `$80F6`; read at `$808B`, `$80EA`, `$8F32`. | `GameStart`, `OptionsPage`, `TitlePage` (`runs/h1`) | `OptionsPage` |
| `$B259` | `Controls` | 1 | The control type, 1-6 (keys or a joystick). Set at `$810D`; read at `$8093`, `$8101`, `$8231` and by the controls reader at `$AE1C`. | `ControlsRead`, `MenuCheckStart`, `OptionsPage`, `TitlePage` (`runs/h1`) | `OptionsPage` |
| `$B25A` | `OptionColour1` | 1 | Colour of the players option line, moved through the cycle at `$8408` by `$8349`. Set at `$8076`; read at `$80B7` (LD DE,`$B25A`), `$80CF`. | `CycleColourRange`, `OptionsPage` | `CycleColourRange`, `OptionsPage`, `TitlePage` (`runs/h1`) |
| `$B25B` | `OptionColour2` | 1 | Colour of the course option line; `$807B`, `$80E6` | `CycleColourRange`, `OptionsPage` | `CycleColourRange`, `OptionsPage`, `TitlePage` (`runs/h1`) |
| `$B25C` | `OptionColour3` | 1 | Colour of the controls option line; `$8080`, `$80FD` | `CycleColourRange`, `OptionsPage` | `CycleColourRange`, `OptionsPage`, `TitlePage` (`runs/h1`) |
| `$B25D` | `BasicStack` | 2 | BASIC's stack pointer, saved at the start (`$8000`). Restored at `$8004`, `$8240`, `$8253`, `$831A` ...; `$80BA` reads it through IX. | `MenuCheckAnyKey`, `MenuCheckStart`, `MenuEntry`, `MenuCheckHeroes` (`runs/a1`), `TitlePage` (`runs/a1`) +1 | `MenuEntry` |
| `$B25F` | `LoopStack` | 2 | The main loop's stack pointer, saved at `$9696`. Restored at `$A689` (life end), `$BB1D` and `$BEE9` (the course switches BeginnerToChampion and ChampionToBeginner). | `BeginnerToChampion` (code), `BonusFlash` (code), `ChampionToBeginner` (code) | `MainLoop` |
| `$B261` | `ObjectWrite` | 2 | Where the next object record is written in ObjectList `$BEF8`. Set at `$96A1`; moved by the script commands (`$96AA`/`$96B4`) and by `$9DAD`/`$9DC6`. | `MainLoop`, `UfoCraterTestLow` (code) | `MainLoop`, `UfoCraterTestLow` (code) |
| `$B263` | `TapeStack` | 2 | The stack pointer saved around a tape load or save. Set at `$826B`; restored at `$827A`, `$82A4`, `$82B5`, `$8304`. | `MenuCheckTape` (`runs/t1`), `TapeErrorHandler` (`runs/t1`) | `MenuCheckTape` (`runs/t1`) |
| `$B265` | `TapeErrSp` | 2 | BASIC's ERR_SP handler, saved around a tape load or save. Set at `$8277`; read at `$82A0`, `$82B1`, `$8300`. | `MenuCheckTape` (`runs/t1`), `TapeErrorHandler` (`runs/t1`) | `MenuCheckTape` (`runs/t1`) |
| `$B267` | `UfoSeen` | 1 | Written by the UFO handler (`$9C75`); never read. The bytes `$B267-$B270` are write-only flags, one set by each object kind when it first runs; nothing reads them. `$B268`, `$B269` and `$B26B` are never touched. | - | `UfoShot` (code) |
| `$B268` | `UnusedFlag1` | 2 | Never read or written | - | - |
| `$B26A` | `PlantSeen` | 1 | Written by the plant handler (`$A390`); never read | - | `PlantHit` (code) |
| `$B26B` | `UnusedFlag2` | 1 | Never read or written | - | - |
| `$B26C` | `FlyerSeen` | 1 | Written by the low flyer handler (`$A107`); never read | - | `LowFlyerScoreRotate` (code) |
| `$B26D` | `UfoWaveSeen` | 1 | Written by the UFO handler (`$9B96`); never read | - | `UfoKindSet` (code) |
| `$B26E` | `BoulderSeen` | 1 | Written by the boulder handler (`$A213`); never read | - | `BoulderExplodeSet` (code) |
| `$B26F` | `RockSeen` | 1 | Written by the rock handler (`$9A28`); never read | - | `ObjRock` |
| `$B270` | `TankSeen` | 1 | Written by the tank handler (`$9F22`); never read | - | `TankHit` (code) |
| `$B271` | `Player` | 1 of 27 | The current player's record, 27 bytes: number, score, extra-life mark, course state, lives, time, flags, initials. The player playing is always here; with two players the routine at `$9022` swaps it with OtherPlayer `$B28C` through SwapBuffer `$B2A7` (three LDIRs of 27 bytes). +0 is the player's number (1 or 2), printed at `$8F80`. | `EntryFieldDraw`, `FireShots`, `GameStart`, `HiScoreEntry`, `HoldCheck` +36 | `FireShots`, `GameStart`, `HoldCheck`, `Im2Clock`, `LifeStart` +19 |
| `$B272` | `PlayerScore` (`Player`+1) | 4 | +1: the score, 4 BCD bytes big-endian (8 digits) | `HiScoreEntry`, `PlayerSwap`, `PrintBcd`, `ScoreAddBcd`, `ScoreCompare` | `GameStart`, `PlayerSwap`, `ScoreAddBcd` |
| `$B276` | `PlayerNextLife` (`Player`+5) | 4 | +5: the score of the next extra life, 4 BCD bytes (00 01 00 00 = 10000 at the start, +20000 after each; none once the score's second byte `$B273` reaches 6) | `PlayerSwap`, `ScoreAddBcd` | `GameStart`, `PlayerSwap`, `ScoreAddMillions` (code) |
| `$B27A` | `PlayerCourse` (`Player`+9) | 2 | +9: the course script pointer (word) | `MainLoop`, `PlayerSwap`, `BestTimeWrite` (code), `MainLoopTimer` (code) | `GameStart`, `MainLoop`, `PlayerSwap`, `BeginnerToChampion` (code), `ChampionToBeginner` (code) +2 |
| `$B27C` | `PlayerPoint` (`Player`+11) | 1 | +`$0B`: the point letter code reached (+`$20` on the Champion course) | `HudDraw`, `HudPrintPoint`, `HudPrintScore`, `HudProgress`, `PlayerSwap` +2 | `GameStart`, `PlayerSwap`, `BeginnerToChampion` (code), `ChampionToBeginner` (code), `ObjPointPassed` (code) |
| `$B27D` | `PlayerScenery` (`Player`+12) | 1 | +`$0C`: the scenery, 0 mountains, `$FF` moon base city | `PlayerSwap`, `SceneryColours`, `ScenerySetup`, `OptionsPage` (`runs/a1`), `DemoPage` (code) +1 | `GameStart`, `PlayerSwap`, `OptionsPage` (`runs/a1`), `DemoPage` (code), `ScoreAdvancePage` (code) +1 |
| `$B27E` | `PlayerLights` (`Player`+13) | 1 | +`$0D`: the warning lights state, drawn by `$927E` | `HudLamps`, `PlayerSwap` | `GameStart`, `LifeStart`, `PlayerSwap`, `ObjLampsSet` (code) |
| `$B27F` | `PlayerRestart` (`Player`+14) | 2 | +`$0E`: the script pointer a new life restarts from (word) | `MainLoop`, `PlayerSwap`, `MainLoopPass` (code) | `GameStart`, `MainLoop`, `PlayerSwap`, `ObjPointPassed` (code) |
| `$B281` | `PlayerSegment` (`Player`+16) | 2 | +`$10`: the script pointer of the current point (word) | `PlayerSwap`, `ObjPointPassed` (code) | `GameStart`, `MainLoop`, `PlayerSwap`, `MainLoopTimer` (code) |
| `$B283` | `PlayerActive` (`Player`+18) | 1 | +`$12`: nonzero while this player still has lives (word; `$8F6B` clears the other player's in a one-player game) | `GameStart`, `PlayerSwap`, `GameAfterLife` (code), `GameOverHold` (code) | `GameStart`, `PlayerSwap`, `GameOverPlayer` (code) |
| `$B284` | `PlayerLives` (`Player`+19) | 1 | +`$13`: lives left (4 at the start, decremented at `$8F74`) | `GameStart`, `HudLives`, `PlayerSwap`, `GameAfterLife` (code), `ScoreAddMillions` (code) | `GameStart`, `PlayerSwap`, `ScoreAddMillions` (code) |
| `$B285` | `PlayerTime` (`Player`+20) | 2 | +`$14`: the sector time, 2 BCD bytes | `Im2Clock`, `PlayerSwap`, `PrintBcd`, `BestTimeCheck` (code), `BestTimeWrite` (code) +1 | `GameStart`, `Im2Clock`, `PlayerSwap`, `OptionsPage` (`runs/a1`), `BonusFlash` (code) +1 |
| `$B287` | `PlayerFrames` (`Player`+22) | 1 | +`$16`: interrupts counted to 50 for each second | `Im2Clock`, `PlayerSwap` | `GameStart`, `Im2Clock`, `PlayerSwap`, `OptionsPage` (`runs/a1`), `BonusFlash` (code) +1 |
| `$B288` | `PlayerFlags` (`Player`+23) | 1 | +`$17`: bit 0 the T key's latch, bit 1 the fire latch, bit 3 set by the mine and plant handlers (`$9B15`, `$A30B`; read by the ground at `$A994`), bit 4 hold, bit 7 tune off (the T key toggles it, `$AF27`; the demo sets it, `$8199`) | `FireShots`, `GameStart`, `HoldCheck`, `PlayerSwap`, `ScrollRoad` +5 | `FireShots`, `GameStart`, `HoldCheck`, `PlayerSwap`, `TuneToggleCheck` +4 |
| `$B289` | `PlayerInitials` (`Player`+24) | 3 | +`$18`: three initials ("JAS" in the image) | `EntryFieldDraw`, `HiScoreEntry`, `PlayerSwap` | `PlayerSwap`, `EntryFieldEdit` (`runs/g1`) |
| `$B28C` | `OtherPlayer` | 27 | The other player's record, same layout as Player `$B271` (player 2, initials "MIK" in the image) | `PlayerSwap` | `PlayerSwap` |
| `$B2A7` | `SwapBuffer` | 27 | 27 bytes used by the routine at `$9022` to swap Player and OtherPlayer | `PlayerSwap` | `PlayerSwap` |

## tables

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$B2C2` | `BuildDate0245` | 20 | A print string with the build date 02:45 29/10/84, disabled like BuildDate0335 `$7F00`. Bytes: `$1F` (the end, where an AT `$16` would be), x 0, line `$31`, FONT 2 (`$1A` `$02`), "02:45 29/10/84", `$1F`. Printed by the life start at `$912C` (LD HL,`$B2C2`; CALL `$FFD0`): only the first byte is read (game 20, a1 4, g1 4, p2 8, h1 4, i1 6, i2 6), nothing appears. | `PrintText` | - |
| `$B2D6` | `SpriteTable` | 528 | The sprite table: 132 entries of two words, drawer and graphics, indexed by sprite number. The sprite drawer `$A826` takes A = sprite number, reads the entry at `$B2D6` + 4A and jumps to the drawer (JP (IX)) with HL = graphics, H = x, L = y. The drawers and their formats: see the graphics A module. An entry with drawer 0 is empty. 472 of the 528 bytes are read (the empty entries and the never-drawn `$5C-$5F` are not). | `DrawSprite` | - |
| `$B4E6` | `Tune` | 768 of 770 | The tune played through the game: 384 words, one note every 3 interrupts, `$FFFF` ends it. The interrupt routine (from `$7F47`) counts TuneDivider `$B240` down from 3; at 0 it takes the word at TunePointer `$B23E`. `$0000` is a rest; another word is the period HL for the ROM BEEPER, with the duration DE chosen so a note lasts about 12 ms. `$FFFF` sends the pointer back to `$B4E6` (`$7F70`). PlayerFlags bit 7 silences it. All 770 bytes (with the end word) are read in the runs. | `TunePlayer` | - |
| `$B7E6` | `TuneEnd` (`Tune`+768) | 2 | `$FFFF`: start again | - | - |

## courses

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$B7E8` | `BeginnerCourse` | 16 of 799 | The Beginner course script, points A-Z in five sectors (E, J, P, U, Z). Chosen by the game start (`$8F2F` LD BC,`$B7E8`) and by ChampionToBeginner `$BED4`; i1 plays it to Z. The first segment (i1 frame 160): Wait 127; Craters 20 80; Rocks 50 110. BeginnerBestE `$B884`: the best time for the sector to E, BCD, rewritten when beaten BeginnerAfterE `$B886`: the segment after the sector end BeginnerBestJ `$B925`: the best time for the sector to J, BCD, rewritten when beaten BeginnerAfterJ `$B927`: the segment after the sector end BeginnerBestP `$B9AE`: the best time for the sector to P, BCD, rewritten when beaten BeginnerAfterP `$B9B0`: the segment after the sector end BeginnerBestU `$BA51`: the best time for the sector to U, BCD, rewritten when beaten BeginnerAfterU `$BA53`: the segment after the sector end BeginnerBestZ `$BB03`: the best time for the sector to Z, BCD, rewritten when beaten | `CmdCraters`, `CmdLamps`, `CmdPoint`, `CmdRocks`, `CmdUfos` +2 | - |
| `$B7F8` | `BeginnerPointA` (`BeginnerCourse`+16) | 25 | point A | `CmdLamps`, `CmdPoint`, `CmdUfos`, `CourseRun`, `SegmentLength` | - |
| `$B811` | `BeginnerPointB` (`BeginnerCourse`+41) | 28 | point B | - | - |
| `$B82D` | `BeginnerPointC` (`BeginnerCourse`+69) | 34 | point C | - | - |
| `$B84F` | `BeginnerPointD` (`BeginnerCourse`+103) | 28 | point D | - | - |
| `$B86B` | `BeginnerPointE` (`BeginnerCourse`+131) | 19 | point E | - | - |
| `$B87E` | `BeginnerSectorE` (`BeginnerCourse`+150) | 6 | SectorEnd after point E | - | - |
| `$B884` | `BeginnerBestE` (`BeginnerCourse`+156) | 2 | - | - | - |
| `$B886` | `BeginnerAfterE` (`BeginnerCourse`+158) | 16 | - | - | - |
| `$B896` | `BeginnerPointF` (`BeginnerCourse`+174) | 34 | point F | - | - |
| `$B8B8` | `BeginnerPointG` (`BeginnerCourse`+208) | 30 | point G | - | - |
| `$B8D6` | `BeginnerPointH` (`BeginnerCourse`+238) | 31 | point H | - | - |
| `$B8F5` | `BeginnerPointI` (`BeginnerCourse`+269) | 32 | point I | - | - |
| `$B915` | `BeginnerPointJ` (`BeginnerCourse`+301) | 10 | point J | - | - |
| `$B91F` | `BeginnerSectorJ` (`BeginnerCourse`+311) | 6 | SectorEnd after point J | - | - |
| `$B925` | `BeginnerBestJ` (`BeginnerCourse`+317) | 2 | - | - | - |
| `$B927` | `BeginnerAfterJ` (`BeginnerCourse`+319) | 15 | - | - | - |
| `$B936` | `BeginnerPointK` (`BeginnerCourse`+334) | 18 | point K | - | - |
| `$B948` | `BeginnerPointL` (`BeginnerCourse`+352) | 20 | point L | - | - |
| `$B95C` | `BeginnerPointM` (`BeginnerCourse`+372) | 36 | point M | - | - |
| `$B980` | `BeginnerPointN` (`BeginnerCourse`+408) | 21 | point N | - | - |
| `$B995` | `BeginnerPointP` (`BeginnerCourse`+429) | 19 | point P | - | - |
| `$B9A8` | `BeginnerSectorP` (`BeginnerCourse`+448) | 6 | SectorEnd after point P | - | - |
| `$B9AE` | `BeginnerBestP` (`BeginnerCourse`+454) | 2 | - | - | - |
| `$B9B0` | `BeginnerAfterP` (`BeginnerCourse`+456) | 17 | - | - | - |
| `$B9C1` | `BeginnerPointQ` (`BeginnerCourse`+473) | 36 | point Q | - | - |
| `$B9E5` | `BeginnerPointR` (`BeginnerCourse`+509) | 33 | point R | - | - |
| `$BA06` | `BeginnerPointS` (`BeginnerCourse`+542) | 27 | point S | - | - |
| `$BA21` | `BeginnerPointT` (`BeginnerCourse`+569) | 23 | point T | - | - |
| `$BA38` | `BeginnerPointU` (`BeginnerCourse`+592) | 19 | point U | - | - |
| `$BA4B` | `BeginnerSectorU` (`BeginnerCourse`+611) | 6 | SectorEnd after point U | - | - |
| `$BA51` | `BeginnerBestU` (`BeginnerCourse`+617) | 2 | - | - | - |
| `$BA53` | `BeginnerAfterU` (`BeginnerCourse`+619) | 27 | - | - | - |
| `$BA6E` | `BeginnerPointV` (`BeginnerCourse`+646) | 21 | point V | - | - |
| `$BA83` | `BeginnerPointW` (`BeginnerCourse`+667) | 21 | point W | - | - |
| `$BA98` | `BeginnerPointX` (`BeginnerCourse`+688) | 32 | point X | - | - |
| `$BAB8` | `BeginnerPointY` (`BeginnerCourse`+720) | 55 | point Y | - | - |
| `$BAEF` | `BeginnerPointZ` (`BeginnerCourse`+775) | 14 | point Z | - | - |
| `$BAFD` | `BeginnerSectorZ` (`BeginnerCourse`+789) | 6 | SectorEnd after point Z | - | - |
| `$BB03` | `BeginnerBestZ` (`BeginnerCourse`+795) | 2 | - | - | - |
| `$BB05` | `BeginnerSwitch` (`BeginnerCourse`+797) | 2 | the word `$BB07` | - | - |
| `$BB24` | `ChampionCourse` | 23 of 944 | The Champion course script, points A-Z in five sectors. Chosen by the game start (`$8F3A` LD BC,`$BB24`) and by BeginnerToChampion `$BB07`; i2 plays it to Z. The first segment (i2 frame 340): Wait 127; Lights 15:1; UfosA 48 48 48; UfosB 48 48 48. ChampionBestE `$BBC7`: the best time for the sector to E, BCD, rewritten when beaten ChampionAfterE `$BBC9`: the segment after the sector end ChampionBestJ `$BC95`: the best time for the sector to J, BCD, rewritten when beaten ChampionAfterJ `$BC97`: the segment after the sector end ChampionBestP `$BD42`: the best time for the sector to P, BCD, rewritten when beaten ChampionAfterP `$BD44`: the segment after the sector end ChampionBestU `$BDF0`: the best time for the sector to U, BCD, rewritten when beaten ChampionAfterU `$BDF2`: the segment after the sector end ChampionBestZ `$BED0`: the best time for the sector to Z, BCD, rewritten when beaten | - | - |
| `$BB3B` | `ChampionPointA` (`ChampionCourse`+23) | 23 | point A | - | - |
| `$BB52` | `ChampionPointB` (`ChampionCourse`+46) | 28 | point B | - | - |
| `$BB6E` | `ChampionPointC` (`ChampionCourse`+74) | 33 | point C | - | - |
| `$BB8F` | `ChampionPointD` (`ChampionCourse`+107) | 27 | point D | - | - |
| `$BBAA` | `ChampionPointE` (`ChampionCourse`+134) | 23 | point E | - | - |
| `$BBC1` | `ChampionSectorE` (`ChampionCourse`+157) | 6 | SectorEnd after point E | - | - |
| `$BBC7` | `ChampionBestE` (`ChampionCourse`+163) | 2 | - | - | - |
| `$BBC9` | `ChampionAfterE` (`ChampionCourse`+165) | 38 | - | - | - |
| `$BBEF` | `ChampionPointF` (`ChampionCourse`+203) | 37 | point F | - | - |
| `$BC14` | `ChampionPointG` (`ChampionCourse`+240) | 40 | point G | - | - |
| `$BC3C` | `ChampionPointH` (`ChampionCourse`+280) | 31 | point H | - | - |
| `$BC5B` | `ChampionPointI` (`ChampionCourse`+311) | 33 | point I | - | - |
| `$BC7C` | `ChampionPointJ` (`ChampionCourse`+344) | 19 | point J | - | - |
| `$BC8F` | `ChampionSectorJ` (`ChampionCourse`+363) | 6 | SectorEnd after point J | - | - |
| `$BC95` | `ChampionBestJ` (`ChampionCourse`+369) | 2 | - | - | - |
| `$BC97` | `ChampionAfterJ` (`ChampionCourse`+371) | 21 | - | - | - |
| `$BCAC` | `ChampionPointK` (`ChampionCourse`+392) | 29 | point K | - | - |
| `$BCC9` | `ChampionPointL` (`ChampionCourse`+421) | 21 | point L | - | - |
| `$BCDE` | `ChampionPointM` (`ChampionCourse`+442) | 40 | point M | - | - |
| `$BD06` | `ChampionPointN` (`ChampionCourse`+482) | 35 | point N | - | - |
| `$BD29` | `ChampionPointP` (`ChampionCourse`+517) | 19 | point P | - | - |
| `$BD3C` | `ChampionSectorP` (`ChampionCourse`+536) | 6 | SectorEnd after point P | - | - |
| `$BD42` | `ChampionBestP` (`ChampionCourse`+542) | 2 | - | - | - |
| `$BD44` | `ChampionAfterP` (`ChampionCourse`+544) | 21 | - | - | - |
| `$BD59` | `ChampionPointQ` (`ChampionCourse`+565) | 31 | point Q | - | - |
| `$BD78` | `ChampionPointR` (`ChampionCourse`+596) | 29 | point R | - | - |
| `$BD95` | `ChampionPointS` (`ChampionCourse`+625) | 24 | point S | - | - |
| `$BDAD` | `ChampionPointT` (`ChampionCourse`+649) | 47 | point T | - | - |
| `$BDDC` | `ChampionPointU` (`ChampionCourse`+696) | 14 | point U | - | - |
| `$BDEA` | `ChampionSectorU` (`ChampionCourse`+710) | 6 | SectorEnd after point U | - | - |
| `$BDF0` | `ChampionBestU` (`ChampionCourse`+716) | 2 | - | - | - |
| `$BDF2` | `ChampionAfterU` (`ChampionCourse`+718) | 21 | - | - | - |
| `$BE07` | `ChampionPointV` (`ChampionCourse`+739) | 26 | point V | - | - |
| `$BE21` | `ChampionPointW` (`ChampionCourse`+765) | 35 | point W | - | - |
| `$BE44` | `ChampionPointX` (`ChampionCourse`+800) | 47 | point X | - | - |
| `$BE73` | `ChampionPointY` (`ChampionCourse`+847) | 64 | point Y | - | - |
| `$BEB3` | `ChampionPointZ` (`ChampionCourse`+911) | 23 | point Z | - | - |
| `$BECA` | `ChampionSectorZ` (`ChampionCourse`+934) | 6 | SectorEnd after point Z | - | - |
| `$BED0` | `ChampionBestZ` (`ChampionCourse`+940) | 2 | - | - | - |
| `$BED2` | `ChampionSwitch` (`ChampionCourse`+942) | 2 | the word `$BED4` | - | - |
| `$BEF0` | `CourseLeftover` | 8 | Leftover: 8 bytes after the scripts (`$02` `$BB` `$5A` `$30` `$5F` `$EE` `$3D` `$A8`), never read | - | - |

## objectlist

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$BEF8` | `ObjectList` | 669 | The live objects: one record per object, written by the course commands, run each pass. Each record starts with the handler's address (a word) and the handler's own bytes; the first of them is the countdown before the object appears. The script commands write records at ObjectWrite `$B261` (from `$96A1`: LD HL,`$BEF8`); the main loop runs the list through `$9745` (`$974A` LD HL,`$BEF8`) and the interpreter at `$9751`, which stops at the end word `$975E`. The tape menu also clears it (`$8288` LD IX,`$BEF8`, `$830F`). The record sizes the commands write: 20 bytes for a UFO (`$9B6B`), 14 a tank (`$9EBD`), 9 a low flyer (`$A03B`), 8 a boulder (`$A196`) or a plant (`$A2C6`). `$BEF8-$C194` is written in the runs. | `BoxOverlap`, `CourseRun`, `ObjCrater`, `ObjLamps`, `ObjPoint` +3 | `CmdCraters`, `CmdLamps`, `CmdPoint`, `CmdRocks`, `CmdUfos` +8 |
| `$C195` | `FreeSpace` | 359 | Never written in the runs: free space between the object list and the stack (`$C195-$C2FB`), zero in the image | - | - |
| `$C2FC` | `Stack` | 84 | The machine stack below BASIC's RAMTOP: the game keeps BASIC's stack (BasicStack `$B25D`); written from `$C2FC` to `$C34F` in the runs (`$C2FC-$C311` by the IM 2 handler, its pushes and BEEPER's, which the L1 counters miss; `$C312-$C337` seen by them) | - | `DrawSprite16x9`, `SpriteXor2Wide` (`runs/a1`) |

## graphicsb

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C350` | `BurstTiny` | 256 | The small boulder's burst (sprites `$80-$83`): 4 frames of 2x8 bytes, 4 slots of 16. Drawer `$B003`: 2 bytes x 8 lines, slot = x AND 6, 64 bytes a frame, frames at `$C350`, `$C390`, `$C3D0`, `$C410`. The boulder handler sets a small boulder's frame to `$7F` (`$A1EA`) and counts it to `$83` (`$A29C`). Read only in i2, 96 of 256 bytes. | - | `DrawSprite16x9`, `SpriteXor2Wide` (`runs/a1`) |
| `$C450` | `PlantFrames` | 2048 | The plant (sprites `$64-$72`): 8 frames of 4x16 bytes, 4 slots of 64; the sprites play them forward then back. Drawer `$B184`: 4 bytes x 16 lines, slot = x AND 6, 256 bytes a frame, frames at `$C450` + `$100` n (n 0-7). Sprites `$64-$6B` are frames 1-8, `$6C-$72` frames 7-1. The plant handler at `$A2C6` draws sprite `$63` + its step. Read in i2 66176 times and in a1 1284 (the score table); 1024 of 2048 bytes. | `DrawSprite16x9`, `DrawSprite32x16` (`runs/a1`), `SpriteXor2Wide` (`runs/a1`) | `DrawSprite16x9`, `SpriteXor2Wide` (`runs/a1`) |
| `$CC50` | `PlantSpray` | 1024 | The plant's spray (sprites `$74-$7A`): 4 frames of 4x16, played forward then back. Drawer `$B184` as PlantFrames. Sprites `$74-$77` are frames 1-4, `$78-$7A` frames 3-1; the plant handler uses step + `$6F` for steps 5-`$0B` (`$A2E3`). All 1024 bytes read, in i2 only. | - | - |
| `$D050` | `BoulderLarge` | 768 | The big boulder (sprites `$4C-$57`): 4 frames of 3x16, each used by three sprites. Drawer `$B10D`: 3 bytes x 16 lines, slot = x AND 6, 192 bytes a frame, frames at `$D050`, `$D110`, `$D1D0`, `$D290`. The course command gives the kind's first sprite (`$40` / `$44` / `$4C`); the handler at `$A196` steps the sprite number through the kind's range, and consecutive numbers share a frame (three here, two for the medium boulder), so the picture changes every third step. Read in i2 46080 times and in a1 / t1. | `SpriteXor3Wide` (`runs/a1`) | - |
| `$D350` | `BoulderMedium` | 576 | The medium boulder (sprites `$44-$4B`): 4 frames of 3x12, each used by two sprites. Drawer `$B0E2`: 3 bytes x 12 lines, 4 slots of 36, 144 bytes a frame, frames at `$D350`, `$D3E0`, `$D470`, `$D500`. Read in i2, a1 and t1. | `SpriteXor3Wide` (`runs/a1`) | - |
| `$D590` | `BoulderSmall` | 256 | The small boulder (sprites `$40-$43`): 4 frames of 2x8, 4 slots of 16. Drawer `$B003`: 64 bytes a frame, frames at `$D590`, `$D5D0`, `$D610`, `$D650`. 128 of 256 bytes read (i2, a1, t1). | `SpriteXor2Wide` (`runs/a1`) | - |
| `$D690` | `UfoBomb` | 128 | The UFO bombs (sprites `$1D`, `$1E`): 2 frames of 2x4 bytes, 8 slots of 8. Drawer `$AFDD`: 2 bytes x 4 lines, slot = x AND 7, 64 bytes a frame. `$1D` is the falling bomb (`$9892` stores it in a new bomb), `$1E` the bomb landing (`$9D61`). Read in i1 and i2  and in a1 / t1. | `SpriteXor2Wide` (`runs/a1`) | - |
| `$D710` | `LowFlyer` | 192 | The low flyer (sprite `$14`): 3x8 bytes, 8 shift slots of 24. Drawer `$B0BA`: 3 bytes x 8 lines, slot = x AND 7, 192 bytes. Its handler is at `$A03B` (record `$9903`); the tank's record also holds sprite `$14` (`$98DA`). Read in i2, a1 and t1. | `SpriteXor3Wide` (`runs/a1`) | - |
| `$D7D0` | `Tank` | 512 | The tank (sprite `$13`): 5x23 bytes, 4 shift slots of 128. Drawer `$B1C8` (as the buggy): 115 bytes of each 128-byte slot used, slot = x AND 6. The handler at `$9EBD`; its explosion is sprites `$33-$36` (BuggyExplosion's first frames). 460 of 512 bytes read: the padding never is. Read in i1, i2, a1, t1. | `DrawSprite40x23` (`runs/a1`) | - |
| `$D9D0` | `Mine` | 128 | The mine (sprites `$11`, `$12`): 2 blink frames of 2x4 bytes, 8 slots of 8. Drawer `$AFDD`. The mine handler at `$9AEB` draws sprite `$11` + bit 2 of PassCount `$B23B` (`$9B42`), so the mine blinks every 4 passes. Only 40 of 128 bytes are read (i1, i2, a1, t1). | `SpriteXor2Wide` (`runs/a1`) | - |
| `$DA50` | `BombCrater` | 192 | The crater a UFO bomb leaves (sprite `$10`): 3x16, 4 slots of 48. Drawer `$B10D`, 192 bytes; drawn by the crater handler at `$9A92`. All read (i1, i2, a1, t1). | `SpriteXor3Wide` (`runs/a1`) | - |
| `$DB10` | `Rock` | 144 | The rock (sprite `$0F`): 3x12, 4 slots of 36. Drawer `$B0E2`, 144 bytes; the rock handler at `$99C3`. Read in every build (game 37188 times). | `DrawSprite24x12`, `SpriteXor3Wide` (`runs/a1`) | - |
| `$DBA0` | `Spinner` | 768 | The spinner, the third UFO kind (sprites `$0B-$0E`): 4 frames of 3x16 with colour, 4 slots of 48. Drawer `$B115`: 3 bytes x 16 lines and the colour of 3x3 cells, 192 bytes a frame, frames at `$DBA0`, `$DC60`, `$DD20`, `$DDE0`. The UFO handler at `$9B6B` animates it (`$9C93` LD A,`$0B` is its base). Read in i1, i2, a1, t1. | `SpriteXor3Wide` (`runs/a1`) | - |
| `$DEA0` | `UfoB` | 384 | The second UFO kind (sprites `$05-$0A`): 4 frames of 3x8 with colour, played 1 2 3 4 3 2. Drawer `$B069`: 3 bytes x 8 lines, 4 slots of 24, 96 bytes a frame, frames at `$DEA0`, `$DF00`, `$DF60`, `$DFC0`. Base sprite `$05` (`$9C97`). Read in i1, i2, a1, t1. | `SpriteXor3Wide` (`runs/a1`) | - |
| `$E020` | `UfoA` | 288 | The first UFO kind (sprites `$01-$04`): 3 frames of 3x8 with colour, played 1 2 3 2. Drawer `$B069`, frames at `$E020`, `$E080`, `$E0E0`. Base sprite `$01` (`$9C9B`). Read in i1, i2, a1, t1. | `SpriteXor3Wide` (`runs/a1`) | - |
| `$E140` | `Buggy` | 512 | The moon buggy (sprite `$00`): 5x23 bytes, 4 shift slots of 128. Drawer `$B1C8`: 115 bytes of each 128-byte slot, slot = x AND 6. Drawn every pass by the buggy routine at `$AA0F` (`$AABC` with A = 0 while DeathStep is `$FF`). 460 of 512 bytes read, in every build. | `DrawSprite40x23` | - |
| `$E340` | `MountainsStrip` | 1088 | The mountains, the middle scenery layer (lines 96-127) when the scenery byte is 0: 34 columns of 8 pixels x 32 lines. Column-major: each 32 bytes are one 8-pixel column, top line first; 34 columns = 272 pixels. Drawn whole by `$9590` at the life start, then fed in a column at a time by the middle scroller at `$A89A` (2 pixels every 4 passes) between MiddleStart and MiddleEnd. All 1088 bytes read in game and the other mountain plays. | `SceneryDrawRows`, `ScrollMiddleBand` | - |
| `$E780` | `MoonBaseStrip` | 1088 | The moon base city, the middle layer when the scenery byte is `$FF`: 34 columns x 32 lines. Same format and scroller as MountainsStrip. Chosen by `$9541` from PlayerScenery; read in a1, t1, i1, i2 (the city sectors). | `SceneryDrawRows` (`runs/a1`), `ScrollMiddleBand` (`runs/a1`) | - |
| `$EBC0` | `HillsStrip` | 1088 | The craggy hills, the back layer (lines 64-95), always: 34 columns x 32 lines. Same format; drawn at the life start by `$9590` and scrolled by the far-band scroller at `$A846`, 1 pixel every pass and a new column every 8 passes, the column pointer FarColumn wrapping at `$F000` back to `$EBC0` (`$A858`, `$A862`). Read in every build. | `SceneryDrawRows`, `ScrollFarBand` | - |

## printvars

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$F000` | `PrintY` | 1 | The print position's pixel line (0-184), the top of the next glyph. Set by AT (`$FE8E`) and by a new line (`$FE21`: + line step, less `$B9` past the bottom); read at `$FF2A`. The menus read PrintY and PrintX as one word (`$8B20`, `$8CE7`). | `EntryFieldDraw`, `HeroesDrawTables`, `PrintCharNormal`, `PrintGlyph` | `PrintAtY`, `PrintCharNormal` |
| `$F001` | `PrintX` | 1 | The print position's x in pixels. Set by AT (`$FE78`), TAB (`$FE9E`) and a new line (the left margin, `$FE15`); moved on by each glyph (`$FFCC`). | `EntryFieldDraw`, `HeroesDrawTables`, `PrintGlyph`, `PrintRowsOr`, `PrintColour` (`runs/t1`) +1 | `PrintAtX`, `PrintCharNormal`, `PrintRowsOr`, `PrintColour` (`runs/t1`), `PrintTab` (`runs/a1`) +1 |
| `$F002` | `PrintShift` | 1 | PrintX AND 7: the glyph's shift within its byte (`$FF4B`, read at `$FF74`) | `PrintGlyph` | `PrintGlyph` |
| `$F003` | `PrintCode` | 1 | The character being printed (`$FEF7`, read at `$FF5F`) | `PrintGlyph` | `PrintGlyph` |
| `$F004` | `PrintAttr` | 1 | The attribute of the cells a glyph touches: set by INK, PAPER, FLASH, BRIGHT (`$FE33-$FE73`); stored at `$FFA0` | `PrintBright`, `PrintColour`, `PrintFlash`, `PrintInk`, `PrintPaper` | `PrintBright`, `PrintFlash`, `PrintInk`, `PrintPaper` |
| `$F005` | `PrintMargin` | 1 | The left margin a new line returns to (code `$18`, `$FEAF`) | `PrintCharNormal`, `PrintNewline` (code) | `PrintMarginSet` |
| `$F006` | `PrintLimit` | 1 | The right limit: a glyph that would pass it starts a new line (code `$19`, `$FEC3`; read at `$FF20`) | `PrintGlyph` | `PrintLimitSet` |
| `$F007` | `PrintError` | 1 | Bit 0 is set when a parameter is out of range (`$FEBD`, `$FEEF`); never read | `PrintTakeParam` | `PrintTakeParam` |
| `$F008` | `PrintFont` | 2 | The current font's base: glyph = base + 8 x code (set by FONT, `$FEE1`; read at `$FF65`). Bit 2 of its high byte (`$F009`) tells PrintAttrCheck `$F0F0` to leave the colours alone: set for FontPlain (`$F600`) and the ROM font (`$3C00`). | `PrintAttrCheck`, `PrintGlyph` | `PrintFontSet` |
| `$F00A` | `PrintState` | 2 | The handler of the next code: PrintCharNormal `$FDE3`, or a control code's parameter handler. PrintChar `$FDCC` jumps through it (`$FDD9`). The control code handlers store themselves here (`$FE0A`) and put PrintCharNormal back when their parameter arrives (`$FEE6`). | `PrintChar` | `PrintAtX`, `PrintAtY`, `PrintCharNormal`, `PrintLimitSet`, `PrintTakeParam` +3 |
| `$F00C` | `PrintWidth` | 1 of 6 | The current font's metrics, copied from its descriptor by FONT (`$FED6`): width of most characters | `PrintCharNormal`, `PrintGlyph`, `PrintRowsOr`, `PrintColour` (`runs/t1`) | `PrintFontSet` |
| `$F00D` | `PrintWidthI` (`PrintWidth`+1) | 1 | width of "I" (`$FF02`) | `PrintGlyph` | `PrintFontSet` |
| `$F00E` | `PrintWidthMW` (`PrintWidth`+2) | 1 | width of "M" and "W" (`$FF14`) | `PrintGlyph` | `PrintFontSet` |
| `$F00F` | `PrintWidthSpace` (`PrintWidth`+3) | 1 | width of a space (`$FF07`) | `PrintGlyph` | `PrintFontSet` |
| `$F010` | `PrintLineStep` (`PrintWidth`+4) | 1 | pixel lines from one text line to the next (`$FE18`) | `PrintCharNormal` | `PrintFontSet` |
| `$F011` | `PrintRows` (`PrintWidth`+5) | 1 | glyph rows drawn (`$FF51`, `$FF71`, `$FFAF`) | `PrintGlyph`, `PrintRowsOr`, `PrintColour` (`runs/t1`) | `PrintFontSet` |
| `$F012` | `PrintLines` | 16 | The screen addresses of the glyph's rows (one word a row, up to 8), filled at `$FF4E` from ScreenLineTable plus the byte column | `PrintAttrCheck`, `PrintRowsOr`, `PrintColour` (`runs/t1`) | `PrintGlyph` |
| `$F022` | `PrintShifted` | 16 | The glyph's rows shifted by PrintShift: two bytes a row, up to 8 rows (`$FF6E`), ORed onto the screen at `$FFB2` | `PrintGlyph`, `PrintRowsOr`, `PrintColour` (`runs/t1`) | `PrintGlyph` |
| `$F032` | `PrintSpare` | 78 | 78 zero bytes, never read or written | - | - |
| `$F080` | `PrintCodeTable` | 22 | The handlers of the control codes `$10-$1A`, one word each, read at `$FDFD`. In order: `$10` INK `$FE2E`, `$11` PAPER `$FE3D`, `$12` FLASH `$FE52`, `$13` BRIGHT `$FE65`, `$14` / `$15` `$FE23`, `$16` AT `$FE78`, `$17` TAB `$FE92`, `$18` MARGIN `$FEAA`, `$19` LIMIT `$FEB3`, `$1A` FONT `$FEC7`. | `PrintCharNormal` | - |
| `$F096` | `FontDescriptors` | 32 | Four font descriptors of 8 bytes: width, width of I, width of M/W, width of a space, line step, rows, base (word). FONT n copies descriptor n's six metrics to PrintWidth `$F00C` and its base to PrintFont `$F008` (`$FEC7`). Font 0: 4 4 6 2, step 6, 5 rows, base `$F000` (glyphs FontSmall `$F100`). Font 1: 6 5 6 5, step 9, 6 rows, base `$F300` (FontBold `$F400`); the title sets its step to 8 (`$800A` LD (`$F0A2`),A). Font 2: 6 6 6 6, step 8, 6 rows, base `$F600` (FontPlain `$F700`). Font 3: all 8, base `$3C00`, the ROM font; its descriptor is never read in the runs (no reads of `$F0AE-$F0B5`). | `PrintFontSet` | `MenuEntry`, `TitlePage` (`runs/a1`) |
| `$F0B6` | `PrintSpare2` | 58 | 58 zero bytes, never read or written | - | - |

## printing

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$F0FD` | `PrintPad` | 3 | 3 zero bytes, never read | - | - |
| `$F100` | `FontSmall` | 768 | Font 0: glyphs for `$20-$7F`, 8 bytes each, 5 rows used. Glyph = PrintFont + 8 x code with PrintFont `$F000`, so the table starts at code `$20`. One byte a row, top row first, bits 7-0 left to right, set = ink; only the rows the descriptor names are drawn, the others are zero. The character set follows the Spectrum's (`$5E` up arrow, `$60` pound, `$7F` copyright, lowercase present). 175 of 768 bytes are read in the runs (the characters the game prints). | `PrintGlyph` | - |
| `$F400` | `FontBold` | 768 | Font 1, the thick title font: glyphs `$20-$7F`, 6 rows used. Same layout with base `$F300`. 420 of 768 bytes read. | `PrintGlyph` | - |
| `$F700` | `FontPlain` | 768 | Font 2: glyphs `$20-$7F`, 6 rows used, printed without colours. Same layout with base `$F600`. 246 of 768 bytes read. | `PrintGlyph` | - |
| `$FA00` | `PixelTable` | 512 | For each x 0-255: the byte column (x / 8) and the pixel's bit mask. Indexed by `$FA00` + 2x: by the pixel routines (`$FD80` B = `$7D`, C = x, doubled), and by the copier `$AFAB` (its byte column). Not a font. | `BlitRows`, `BuggyUpdate`, `FlipPixel`, `PlotPixel`, `UnplotPixel` (`runs/a1`) | - |
| `$FC00` | `ScreenLineTable` | 384 | The screen address of each pixel line 0-191 (192 words). Indexed by `$FC00` + 2y (`$7E00` doubled: H = `$7E`, L = y, then SLA L / RL H) by the pixel routines, PrintGlyph (`$FF2D`) and the sprite drawers. The scrollers start at line 64 (`$FC80`), 96 (`$FCC0`), 128 (`$FD00`) and 160 (`$FD40`). A line number past 191 reads past the table into PlotPixel's bytes (the wreck pieces, see BuggyWreck1 `$638A`). | `BlitRows`, `DrawSprite16x9`, `DrawSprite24x12`, `DrawSprite40x23`, `EntryFieldClear` +14 | - |
| `$FFE7` | `PrintResetText` | 12 | INK 0, AT 0 0, MARGIN 0, LIMIT `$FF`, FONT 3, end (`$12` 00 16 00 00 18 00 19 FF 1A 03 1F) | - | - |
| `$FFF3` | `PrintResetPad` | 1 | A zero byte, never read | - | - |
| `$FFF7` | `BuildTag` | 8 | Leftover: "ROYD3313", never read | - | - |
| `$FFFF` | `Im2Vector` | 1 | `$18`, the JR the interrupt lands on: with the byte `$F3` at `$0000` it jumps back 13 to Im2Jump `$FFF4` (run 25747 times in i1) | - | - |
