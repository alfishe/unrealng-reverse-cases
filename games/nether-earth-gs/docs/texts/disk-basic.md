# disk-basic

**What it is.** The BASIC program "neart GS" that starts the disk version (SCL and TRD, Tron Z 2002): it lowers
RAMTOP below the loader, has TR-DOS load the loader `neart022` and runs it.

**The file.** The TR-DOS file `neart GS` (type B, 67 bytes, autostart line 10: `$80 $AA $0A $00` after the
program), loaded at PROG (`$5CCB` under TR-DOS's 48K BASIC). 48K BASIC tokens, ASCII text. The build input is
[`src/res/text/disk-basic.txt`](../../src/res/text/disk-basic.txt), which `tools/basic_tok.py` tokenizes back to
the 67 bytes (the hidden number forms added); [`src/disk/basic.asm`](../../src/disk/basic.asm) adds the autostart
mark. The text is English (BASIC keywords and a file name), no translation needed.

## The listing

One line per program line, as the listing file holds it (a space after each keyword):

```text
10 CLEAR 24999
20 RANDOMIZE USR 15619:REM :LOAD "neart022"CODE 
30 RANDOMIZE USR 25e3
```

- Line 20: `RANDOMIZE USR 15619` enters TR-DOS's command interpreter, which takes the command after `REM :` in the
  same line: `LOAD "neart022" CODE` (the loader, to its catalogue address 25000). The `REM` keeps 48K BASIC from
  executing the TR-DOS command itself.
- Line 30: `25e3` is 25000, `$61A8`, the loader's start.
