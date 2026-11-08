; The BASIC of Exolon: the tape's block 2 (81 bytes), program "exolon", LINE 0. docs/03-build-and-load.md 3.2.
;
;   10 BORDER 0: PAPER 0: INK 7: CLEAR 25999: LOAD "" CODE : RANDOMIZE USR 64512
;   20 REM *************
;
; The header's LINE 0 starts the program at its first line, 10. LOAD "" CODE takes the next file (the loader), at the
; address its header names ($FC00); RANDOMIZE USR 64512 enters it. Line 20's length word says 98 bytes where 18 are
; left (13 asterisks and no end-of-line): LIST shows the asterisks, nothing reads past them. The program is Zynaps'
; (../../zynaps/src/tape/basic.asm) but for the CLEAR: RAMTOP $658F, one below the game file's load address.

  DEVICE ZXSPECTRUM48
  ORG $5CCB                     ; PROG: where the ROM puts a program

; ROM tokens
T_BORDER    EQU $E7
T_PAPER     EQU $DA
T_INK       EQU $D9
T_CLEAR     EQU $FD
T_LOAD      EQU $EF
T_CODE      EQU $AF
T_RANDOMIZE EQU $F9
T_USR       EQU $C0
T_REM       EQU $EA

LoaderStart EQU $FC00           ; the loader's address (its header, and the USR)

; A number as the ROM stores it after its digits: $0E and the 5-byte small integer form
  MACRO NUM text, value
    DB text
    DB $0E, 0, 0, low(value), high(value), 0
  ENDM

Basic:
  DB 0, 10                      ; line 10 (the number is big-endian)
  DW Line10End-Line10
Line10:
  DB T_BORDER
  NUM "0", 0
  DB ":", T_PAPER
  NUM "0", 0
  DB ":", T_INK
  NUM "7", 7
  DB ":", T_CLEAR
  NUM "25999", 25999
  DB ":", T_LOAD, '""', T_CODE, ":", T_RANDOMIZE, T_USR
  NUM "64512", LoaderStart
  DB $0D
Line10End:
  DB 0, 20                      ; line 20
  DW 98                         ; the length: 80 bytes more than the line has
  DB T_REM, "*************"     ; no $0D: the block ends inside the line
BasicEnd:

  SAVEBIN "basic.bin",Basic,BasicEnd-Basic
