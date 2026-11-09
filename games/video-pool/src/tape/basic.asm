; The BASIC of Video Pool: the tape's block 2 (44 bytes), program "VIDEO POOL", LINE 10. docs/03-build-and-load.md 3.1.
;
;   10 CLEAR 32767
;   20 LOAD "" CODE
;   30 RANDOMIZE USR 61440
;
; The header's LINE 10 starts the program at once. Line 10 puts RAMTOP at $7FFF, one below the game's $8000; line 20
; loads the next file (block 4, the turbo loader) at the address its header names, $F000; line 30 runs it. The
; loader never returns: it loads block 5 and jumps to the game (src/turbo/loader.asm).
;
; Hand-written (the kit has no BASIC generator): it assembles to the tape's block 2 byte for byte, checked by
; tools/build.sh.

  DEVICE ZXSPECTRUM48
  ORG $5CCB                     ; PROG: where the ROM puts a program

; ROM tokens
T_CODE      EQU $AF
T_USR       EQU $C0
T_LOAD      EQU $EF
T_RANDOMIZE EQU $F9
T_CLEAR     EQU $FD

LoaderStart EQU $F000           ; the turbo loader's entry (block 4's load address)
RamTop      EQU $7FFF           ; RAMTOP below the game (CLEAR 32767)

; A number as the ROM stores it after its digits: $0E and the 5-byte small integer form
  MACRO NUM text, value
    DB text
    DB $0E, 0, 0, low(value), high(value), 0
  ENDM

Basic:
  DB 0, 10                      ; line 10 (the number is big-endian)
  DW Line10End-Line10
Line10:
  DB T_CLEAR
  NUM "32767", RamTop
  DB $0D
Line10End:
  DB 0, 20                      ; line 20
  DW Line20End-Line20
Line20:
  DB T_LOAD, '""', T_CODE
  DB $0D
Line20End:
  DB 0, 30                      ; line 30
  DW Line30End-Line30
Line30:
  DB T_RANDOMIZE, T_USR
  NUM "61440", LoaderStart
  DB $0D
Line30End:
BasicEnd:

  SAVEBIN "loader.bin",Basic,BasicEnd-Basic
