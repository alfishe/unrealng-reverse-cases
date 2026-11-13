# Front: the texts

Every text of the main block (`$6C3F-$A83E`, src/front/front.ann) as UTF-8 text; the formats are in
tools/res_front.py. A text is quoted, with `\xNN` for a byte outside printable ASCII and `\"`, `\\` escaped.

## PrintText strings

PrintText `$9D72` reads its parameters after the CALL: the font (`small` FontSmall, `large` FontLarge), the start
byte in the 32-byte line (`column`), a pixel shift 0-7 (`shift`), the screen line (`line`: 68, 84, 100, 116 for the
logo box's four text lines), then the text up to a zero byte. Only `A-Z`, the space and (small font) `0-9` have
glyphs; other bytes under `A` show as digit glyphs shifted (`-` as Y, `+` as W, `/` as a space, `.` as Z).

| File | Address | Bytes | Text | Printed by |
| --- | --- | ---: | --- | --- |
| programmed-by.txt | `$9512` | 18 | PROGRAMMED BY | CreditsLoop `$9509` (page 1) |
| neil-dodwell.txt | `$9527` | 17 | NEIL DODWELL | CreditsPage1Name `$9524` |
| graphics-by.txt | `$9551` | 16 | GRAPHICS BY | CreditsPage2 `$9538` |
| concept-animations.txt | `$9564` | 23 | CONCEPT ANIMATIONS | CreditsPage2Name `$9561` |
| produced-by.txt | `$9594` | 16 | PRODUCED BY | CreditsPage3 `$957B` |
| system-three.txt | `$95A7` | 17 | SYSTEM THREE | CreditsPage3Name `$95A4` |
| original-game-design.txt | `$95D1` | 25 | ORIGINAL GAME DESIGN | CreditsPage4 `$95B8` |
| mark-cale.txt | `$95ED` | 14 | MARK CALE | CreditsPage4Name `$95EA` |
| sound-effects-by.txt | `$9614` | 21 | SOUND EFFECTS BY | CreditsPage5 `$95FB` |
| neil-dodwell-sound.txt | `$962C` | 17 | NEIL DODWELL | CreditsPage5Name `$9629` |
| developed.txt | `$9656` | 14 | DEVELOPED | CreditsPage6 `$963D` |
| in-association-with.txt | `$9667` | 24 | IN ASSOCIATION WITH | CreditsPage6Line2 `$9664` |
| marjacq-micro.txt | `$9682` | 18 | MARJACQ MICRO | CreditsPage6Line3 `$967F` |
| copyright-1989.txt | `$96B2` | 19 | COPYRIGHT 1989 | CreditsPage7 `$9694` |
| system-3-software.txt | `$96C8` | 22 | SYSTEM 3 SOFTWARE | CreditsPage7Line2 `$96C5` |
| press-space-to-start.txt | `$96E1` | 25 | PRESS SPACE TO START | CreditsPage7Line3 `$96DE` |
| press-the-key-for.txt | `$9720` | 22 | PRESS THE KEY FOR | DefineKeys `$971A` |
| key-name.txt | `$97A8` | 12 | a 7-byte slot (`RIGHT  ` on the tape) DefineKeysLoop fills with the name and the key | PrintKeyName `$97A5` |
| blank-line.txt | `$9D6B` | 6 | one space; the line patched by ClearTextLine | ClearTextLine `$9D65` |
| kempston.txt | `$A0DC` | 13 | KEMPSTON | JoystickText `$A0D9` |
| cursor-keys.txt | `$A0EC` | 16 | CURSOR KEYS | JoystickText2 `$A0E9` |
| sinclair.txt | `$A0FF` | 13 | SINCLAIR | JoystickText3 `$A0FC` |
| leave-this-menu.txt | `$A10F` | 20 | LEAVE THIS MENU | JoystickText4 `$A10C` |
| press-space-to-select.txt | `$A169` | 26 | PRESS SPACE TO SELECT | MenuTitle `$A166` |
| start-game.txt | `$A187` | 15 | START GAME | MenuLines `$A184` |
| define-keys.txt | `$A199` | 16 | DEFINE KEYS | MenuLines2 `$A196` |
| select-joystick.txt | `$A1AC` | 20 | SELECT JOYSTICK | MenuLines3 `$A1A9` |

## Other texts

| File | Address | Bytes | Format | Read by |
| --- | --- | ---: | --- | --- |
| key-names.txt | `$97B5` (KeyNames) | 35 | one quoted 7-byte name a line: UP, DOWN, LEFT, RIGHT, FIRE | DefineKeysLoop `$9736` |
| old-define-keys.txt | `$A124` (OldDefineKeysTexts) | 66 | a line a text: two parameter bytes, then the quoted text (its 0 implied): PRESS KEY FOR, UP, `DOW\N` (sic), LEFT, RIGHT, FIRE | nothing: an earlier DEFINE KEYS's texts, kept as a documented leftover |
