; The BASIC of Moon Patrol: the tape's block 1 (187 bytes), program "MOONPATROL", LINE 20. docs/03-build-and-load.md 3.1.
;
;   10 RANDOMIZE USR 32768
;   20 BORDER 0: INK 7: BRIGHT 1: PAPER 0: CLEAR 24823: PRINT AT 10,8;"<FLASH 1>   MOON PATROL   <FLASH 0>";
;      AT 12,13;"<INVERSE 1>LOADING<INVERSE 0>": INK 0
;   30 LOAD "" CODE : CLEAR 49999: GO TO 1
;
; The header's LINE 20 starts the program at line 20: the colours, RAMTOP $60F7 (one below the code's load address
; $60F8), the title flashing at row 10 and LOADING in inverse at row 12, then INK 0. Line 30 loads the next file (the
; game, at the address its header names, $60F8), moves RAMTOP up to $C34F (CLEAR 49999, inside the loaded image) and
; goes to line 1: the first line at or after it, 10, enters the game at $8000. The strings hold the ROM's colour
; control codes FLASH ($12) and INVERSE ($14), each followed by its 0 / 1 parameter.

  DEVICE ZXSPECTRUM48
  ORG $5CCB                     ; PROG: where the ROM puts a program

; ROM tokens
T_AT        EQU $AC
T_USR       EQU $C0
T_INK       EQU $D9
T_PAPER     EQU $DA
T_BRIGHT    EQU $DC
T_BORDER    EQU $E7
T_GOTO      EQU $EC
T_LOAD      EQU $EF
T_CODE      EQU $AF
T_PRINT     EQU $F5
T_RANDOMIZE EQU $F9
T_CLEAR     EQU $FD

; Control codes inside a PRINT string
C_FLASH     EQU $12
C_INVERSE   EQU $14

GameStart   EQU $8000           ; the game's entry (the USR)
GameLoad    EQU $60F8           ; the code file's load address (its header); RAMTOP one below it
RamTopPlay  EQU $C34F           ; RAMTOP after the load (CLEAR 49999)

; A number as the ROM stores it after its digits: $0E and the 5-byte small integer form
  MACRO NUM text, value
    DB text
    DB $0E, 0, 0, low(value), high(value), 0
  ENDM

Basic:
  DB 0, 10                      ; line 10 (the number is big-endian)
  DW Line10End-Line10
Line10:
  DB T_RANDOMIZE, T_USR
  NUM "32768", GameStart
  DB $0D
Line10End:
  DB 0, 20                      ; line 20: the autostart line
  DW Line20End-Line20
Line20:
  DB T_BORDER
  NUM "0", 0
  DB ":", T_INK
  NUM "7", 7
  DB ":", T_BRIGHT
  NUM "1", 1
  DB ":", T_PAPER
  NUM "0", 0
  DB ":", T_CLEAR
  NUM "24823", GameLoad-1
  DB ":", T_PRINT, T_AT
  NUM "10", 10
  DB ","
  NUM "8", 8
  DB ";", '"', C_FLASH, 1, "   MOON PATROL   ", C_FLASH, 0, '"'
  DB ";", T_AT
  NUM "12", 12
  DB ","
  NUM "13", 13
  DB ";", '"', C_INVERSE, 1, "LOADING", C_INVERSE, 0, '"'
  DB ":", T_INK
  NUM "0", 0
  DB $0D
Line20End:
  DB 0, 30                      ; line 30
  DW Line30End-Line30
Line30:
  DB T_LOAD, '""', T_CODE, ":", T_CLEAR
  NUM "49999", RamTopPlay
  DB ":", T_GOTO
  NUM "1", 1
  DB $0D
Line30End:
BasicEnd:

  SAVEBIN "loader.bin",Basic,BasicEnd-Basic
