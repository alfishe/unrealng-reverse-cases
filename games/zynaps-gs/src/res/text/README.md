# The texts

UTF-8 text, turned into the bytes and back by `tools/res_text.py` (the round trip is exact):

| File | What | Bytes | Entry |
| --- | --- | --- | --- |
| `messages.msg.txt` | the 28 messages, `msg N: text`, one a line | `$82EE-$8515` (552) | `Messages` (`texts.asm`) |
| `hiscores.hsc.txt` | the high-score table, `score: text \| value`, five lines | `$8261-$82A6` (70) | `HiScoreTable` (`scoredata.asm`) |

A message is the bytes up to `$FF`. PrintMessage `$A423` prints message n: it skips n + 1 `$FF` bytes from `$82ED`, so
the order of the lines is the message number and a message may grow or shrink as long as the total keeps 552 bytes
(the code after it is at a fixed address). PrintString `$A401` prints each byte with PrintChar `$A321`:

| Text | Byte(s) | Meaning |
| --- | --- | --- |
| a letter | `$20-$7E` | the ROM font's character, printed bold; `↑` `£` `©` are the font's `$5E`, `$60`, `$7F` |
| `{attr $xx}` | `$00 xx` | the attribute of what follows (PrintAttr `$80AC`) |
| `{ink n}`, `{paper n}` | `$01 n`, `$02 n` | only the ink, only the paper |
| `{col n}`, `{row n}` | `$03 n`, `$04 n` | the print column, the row (PrintPos `$80AA`) |
| `{col+n}`, `{row+n}` | `$05 n`, `$06 n` | move by n (signed) |
| `{code n $xx}` | `n xx` | the codes 7-`$1A` and `$1C-$1F`: skipped with their byte |
| `{msg n}` | `$1B n` | print message n here |
| `{Gxx}` | `$80-$FE` | the game's own glyph xx (`$B54F` + (xx - `$80`) * 8: the logo, the frame pieces) |
| `{x7B}`, `{x7D}` | `$7B`, `$7D` | the braces themselves |

A code's byte is taken as it is, `$FF` and `$1B` too. Message 23 (`PLAYER n`) has its digit written by `$B034`
(`PlayerDigit`, `$84BB`) before it is printed.

A high-score line is the entry's print string (the position on the screen, the initials and `{msg 8}`, the dotted
line) and its score, 4 BCD bytes written as the decimal number (or `$xxxxxxxx` when the bytes are no BCD). The
table must stay five entries of 14 bytes: the code takes the scores at 14-byte steps (`$826B` at `$A807`, `$829D`
at `$A836`).
