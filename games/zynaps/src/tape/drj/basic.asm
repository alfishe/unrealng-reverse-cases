; The BASIC of the 1993 re-tape (orig/Zynaps.tap.zip, ZYNAPS.TAP block 1: 236 bytes, program "Zynaps", LINE 10).
; docs/03-build-and-load.md 3.6.
;
;    1 REM Zynaps. DRJ 3/12/93 1824
;   10 POKE 23693,7: BORDER NOT PI : CLEAR 24999
;   15 POKE VAL "23739", VAL "111"
;   20 LOAD "zynaps0.c" CODE : RANDOMIZE USR 5e4
;   30 LOAD "zynaps1.c" CODE
;   40 RANDOMIZE USR 32768
;   50 REM Collect icon to advance power-up; hold fire and collect to activate
;
; POKE 23693,7 (ATTR P): white paper; BORDER NOT PI is BORDER 0; CLEAR 24999 puts RAMTOP at $61A7, the SP the
; Hewson loader's stub gives the game; POKE 23739,111 (CURCHL's high byte) sends the ROM's "Bytes:" messages to
; nowhere. zynaps0.c unpacks the loading screen, zynaps1.c is the game from $6801.

  DEVICE ZXSPECTRUM48
  ORG $5CCB

T_REM       EQU $EA
T_POKE      EQU $F4
T_BORDER    EQU $E7
T_NOT       EQU $C3
T_PI        EQU $A7
T_CLEAR     EQU $FD
T_VAL       EQU $B0
T_LOAD      EQU $EF
T_CODE      EQU $AF
T_RANDOMIZE EQU $F9
T_USR       EQU $C0

  MACRO NUM text, value
    DB text
    DB $0E, 0, 0, low(value), high(value), 0
  ENDM

  MACRO LINE number
    DB high(number), low(number)
    DW .end-.body
.body:
  ENDM

Basic:
Line1:
  LINE 1
  DB T_REM, "Zynaps. DRJ 3/12/93 1824", $0D
.end:
Line10:
  LINE 10
  DB T_POKE
  NUM "23693", 23693
  DB ","
  NUM "7", 7
  DB ":", T_BORDER, T_NOT, T_PI, ":", T_CLEAR
  NUM "24999", 24999
  DB $0D
.end:
Line15:
  LINE 15
  DB T_POKE, T_VAL, '"23739"', ",", T_VAL, '"111"', $0D
.end:
Line20:
  LINE 20
  DB T_LOAD, '  "zynaps0.c"', T_CODE, ":", T_RANDOMIZE, T_USR
  NUM "5e4", 50000
  DB $0D
.end:
Line30:
  LINE 30
  DB T_LOAD, '  "zynaps1.c"', T_CODE, $0D
.end:
Line40:
  LINE 40
  DB T_RANDOMIZE, T_USR
  NUM "32768", 32768
  DB $0D
.end:
Line50:
  LINE 50
  DB T_REM, "Collect icon to advance power-up; hold fire and collect to activate", $0D
.end:
BasicEnd:

  SAVEBIN "drj-basic.bin",Basic,BasicEnd-Basic
