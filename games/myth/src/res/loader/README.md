# Loader: the countdown digits

The data of the SpeedLock loader's second stage (src/loader/sl1.ann). The format is in tools/res_resident.py;
`python3 tools/res_formats.py build` turns the file back into the bytes the source `INCBIN`s.

| File | Address | Bytes | Format | Read by |
| --- | --- | ---: | --- | --- |
| countdown-digits.png | `$FF80` (CountdownDigits, tape block 7) | 80 | the digits 0-9, 8 x 8 each, in a row with a grey line between; index 0 paper, 1 ink | CountdownTask `$FC73` (src/loader/reveal.asm): glyph = `$FF80` + 8 x digit, the low bytes in CountdownCounter `$FD07` |

c1: the four digits at character row 20, columns 13-18 (the last digit at `$5092`, the others 2, 3 and 5 columns left of it) count down while the blocks load.
