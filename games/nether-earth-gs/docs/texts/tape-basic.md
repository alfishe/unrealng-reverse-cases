# tape-basic

**What it is.** Hood's BASIC "NetherE GS" that starts the tape version (2017): his credit line, a two-item menu
(music on or off), then every file loaded one by one, each followed by a call into the loader `neart0222`.

**The file.** The first block of the TAP: a Program header "NetherE GS", 961 bytes, autostart line 10, then the
data block. 48K BASIC tokens, ASCII text. The build input is
[`src/res/text/tape-basic.txt`](../../src/res/text/tape-basic.txt), which `tools/basic_tok.py` tokenizes back to
the 961 bytes ([`src/tape/basic.asm`](../../src/tape/basic.asm)). The text is English, no translation needed.

## The texts on screen and in REM

```text
Conversion from TRD by Hood.7.4.2017.hood.speccy.cz
```

(line 1, `REM`: "Conversion from TRD by Hood", the date 7.4.2017 = 7 April 2017, his site hood.speccy.cz)

```text
1-music ON
2-music OFF
```

(line 10, `PRINT "1-music ON"'"2-music OFF"`: the menu, two lines on a black screen; line 11 waits for 1 or 2)

## The listing

One line per program line, as the listing file holds it (a space after each keyword):

```text
1 REM Conversion from TRD by Hood.7.4.2017.hood.speccy.cz
10 BORDER 0:PAPER 0:INK 7:CLEAR 24999:PRINT "1-music ON"'"2-music OFF"
11 LET a$=INKEY$ :IF a$=""OR a$<> "1"AND a$<> "2"THEN GO TO 11
13 POKE 23739,111:LOAD "neart0222"CODE :LOAD "neart000"CODE :RANDOMIZE USR 25561
16 IF a$="2"THEN POKE 25311,201:RANDOMIZE USR 25516:FOR f=1TO 5:RANDOMIZE USR 25561:NEXT f:GO TO 30
20 RANDOMIZE USR 25022:LOAD "neart002"CODE :RANDOMIZE USR 25037:LOAD "neart003"CODE :RANDOMIZE USR 25046:LOAD "neart004"CODE :RANDOMIZE USR 25055:LOAD "neart005"CODE :RANDOMIZE USR 25064:LOAD "neart006"CODE :RANDOMIZE USR 25073
30 LOAD "neart007"CODE :RANDOMIZE USR 25086:LOAD "neart008"CODE :RANDOMIZE USR 25098:LOAD "neart009"CODE :RANDOMIZE USR 25110:LOAD "neart010"CODE :RANDOMIZE USR 25122:LOAD "neart011"CODE :RANDOMIZE USR 25134
40 LOAD "neart012"CODE :RANDOMIZE USR 25146:LOAD "neart013"CODE :RANDOMIZE USR 25158:LOAD "neart014"CODE :RANDOMIZE USR 25170:LOAD "neart015"CODE :RANDOMIZE USR 25182:LOAD "neart016"CODE :RANDOMIZE USR 25194
50 LOAD "neart017"CODE :RANDOMIZE USR 25206:LOAD "neart018"CODE :RANDOMIZE USR 25218:LOAD "neart023"CODE :RANDOMIZE USR 25230:LOAD "neart019"CODE :RANDOMIZE USR 25242:LOAD "neart020"CODE :RANDOMIZE USR 25254
60 LOAD "neart021"CODE :RANDOMIZE USR 25273:LOAD "neart001"CODE :RANDOMIZE USR 25286
```

- Line 13: `POKE 23739,111` changes channel S's output address so the ROM's "Bytes: name" messages stay off the
  loading screen.
- Line 16: with music off, `POKE 25311,201` puts `RET` at the loader's `StartModule` and `USR 25516` resets the card
  only; five `USR 25561` draw the five progress ticks of the module files it skips.
- Lines 20-60: each `LOAD "neartNNN" CODE` is followed by the loader entry that sends that file to the General Sound
  ([`src/tape/loader.asm`](../../src/tape/loader.asm) names every address).
