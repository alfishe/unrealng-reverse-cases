# The BASIC program

The program lines of sector 0 of `boot` (src/basic), as a listing written and read by `tools/res_basic.py` (the same
format as a variant's `basic.txt`, described in the tool's header): one line a program line, a keyword followed by the
one space that belongs to it, `{20}` a space byte at a line's end, `end` the program's end mark `$80`,
`autostart N` TR-DOS's `$AA` and the line to start at.

| File | Entries | Bytes | What |
| --- | --- | ---: | --- |
| `launch-lines.txt` | LaunchLine `$5D3B` (with LaunchToken, LaunchName, LaunchSuffix), LineTwo `$5D59`, LineThree `$5D6C` | 64 | lines 1-3: the launch line RunLetter `$6A51` rewrites (`RUN "        "`), the TR-DOS `RUN` of line 2, the TR-DOS command line of line 3 |
| `line-ten.txt` | LineTen `$5DC6`, AutostartMark `$5DEF` | 45 | line 10, the autostart line (`CLEAR VAL "65347"`, `RANDOMIZE USR VAL "23936"`, `RUN`), the end mark and `autostart 10` |

Line 4 is not here: it is the REM that holds the loader's machine code (Loader `$5D80`, a code entry of
`src/basic/basic.ann`); its 5-byte header and its `$0D` stay bytes around the code. The label LaunchToken and the
others inside line 1 split the resource's `INCBIN`s, so RunLetter still writes to them by name. A variant whose BASIC
sector differs keeps the whole sector as its own `basic.txt` (`variants/NAME/basic.txt`).
