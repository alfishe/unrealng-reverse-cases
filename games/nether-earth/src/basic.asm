; The BASIC of Nether Earth: the tape's block 1 (381 bytes), program "N.EARTH", LINE 0. docs/03-build-and-load.md.
;
; One line, number 0, whose length word says 65535: LIST stops at it and shows nothing, and the program runs all the
; same (the ROM finds the next statement by the colons, not by the length). Its statements, in order:
;
;   CLEAR 65535: POKE 23624,0: INK 0: PAPER 0: CLS: PRINT AT 20,0;: POKE 23659,0:
;   LOAD "" CODE 64730: RANDOMIZE USR 64730: REM (c)1986 APS ... (c) Argus Press Software
;
; POKE 23624,0 (BORDCR) makes the border black, POKE 23659,0 (DF_SZ) takes the lower screen's two lines away, so the
; ROM prints no "Bytes: N1" over the picture. The colour codes INK 7 / PAPER 7 ($10 $07, $11 $07) in the line make a
; listing's text white on white: a mangled LIST still shows nothing. The REM holds the copyright notice.

  DEVICE ZXSPECTRUM48
  ORG $5CCB

; ROM tokens
T_CLEAR     EQU $FD
T_POKE      EQU $F4
T_INK       EQU $D9
T_PAPER     EQU $DA
T_CLS       EQU $FB
T_PRINT     EQU $F5
T_AT        EQU $AC
T_LOAD      EQU $EF
T_CODE      EQU $AF
T_RANDOMIZE EQU $F9
T_USR       EQU $C0
T_REM       EQU $EA
C_INK       EQU $10         ; control codes inside a line
C_PAPER     EQU $11
COPYRIGHT   EQU $7F         ; the (c) character

; A number as the ROM stores it after its digits: $0E and the 5-byte small integer form
  MACRO NUM text, value
    DB text
    DB $0E, 0, 0, low(value), high(value), 0
  ENDM

; INK 7 / PAPER 7 pairs, white on white
  MACRO HIDE count
    DUP count
      DB C_INK, 7
    EDUP
  ENDM

Basic:
  DB 0, 0                       ; line 0
  DW $FFFF                      ; the length: LIST shows nothing
  DB C_INK, 7, C_PAPER, 7
  HIDE 11
  DB C_PAPER, 7, C_INK, 7
  DB T_CLEAR
  NUM "65535", 65535
  DB ":", T_POKE
  NUM "23624", 23624
  DB ","
  NUM "0", 0
  DB ":", T_INK
  NUM "0", 0
  DB ":", T_PAPER
  NUM "0", 0
  DB ":", T_CLS, ":", T_PRINT, T_AT
  NUM "20", 20
  DB ","
  NUM "0", 0
  DB ";:", T_POKE
  NUM "23659", 23659
  DB ","
  NUM "0", 0
  DB ":", T_LOAD, '""', T_CODE
  HIDE 15
  NUM "64730", 64730
  DB ":", T_RANDOMIZE, T_USR
  NUM "64730", 64730
  DB ":", T_REM, "           "
  ; the copyright notice, in the REM: "(c)1986 APS" white on white, then red bars round "(c) Argus Press Software", blue on white
  DB C_INK, 7, C_PAPER, 7, " ", COPYRIGHT, "1986 APS"
  DB "                                          "
  DB C_INK, 7, C_PAPER, 7, "      ", C_PAPER, 2
  DB "                        "
  DB C_PAPER, 7, "        ", C_PAPER, 2, " "
  DB C_INK, 1, C_PAPER, 7, COPYRIGHT, " Argus Press Software", C_PAPER, 2, " "
  DB C_PAPER, 7, "        ", C_PAPER, 2
  DB "                        "
  DB C_PAPER, 7, "       "
  DB $0D

  SAVEBIN "basic.bin",Basic,$-Basic
