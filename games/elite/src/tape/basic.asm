; The BASIC of Elite: TZX block 3 (387 bytes), program "E L I T E", LINE 0, the variables at offset 200.
; docs/03-build-and-load.md 3.2 and 3.3.
;
;    0 BORDER 0: INK 0: PAPER 7{=0}: CLS : PRINT AT 12{=21},11;"*LOADING*": POKE 23613{=20107},0{=255}:
;      RANDOMIZE USR (PEEK 23627+256*PEEK 23628)
;    1 SAVE "E L I T E" LINE 0
;    2 REM *** SOFTLOCKtm 1984 ***
;
; The numbers in braces are the five-byte values the interpreter uses; LIST shows only the digits before them.
; PEEK 23627+256*PEEK 23628 is VARS: the program ends at offset 200 and the "variables" are the stub at $5D93,
; which USR enters. The stub sums the screen the BASIC leaves and decrypts its own tail with the sum
; (StubDecrypt): this file is the stub in clear, and tools/mktape.py encrypts the tail from StubTail on with
; ScreenKey after sjasmplus has assembled it.

  DEVICE ZXSPECTRUM48
  ORG $5CCB                     ; PROG: where the ROM puts a program

; ROM tokens
T_BORDER    EQU $E7
T_INK       EQU $D9
T_PAPER     EQU $DA
T_CLS       EQU $FB
T_PRINT     EQU $F5
T_AT        EQU $AC
T_POKE      EQU $F4
T_RANDOMIZE EQU $F9
T_USR       EQU $C0
T_PEEK      EQU $BE
T_SAVE      EQU $F8
T_LINE      EQU $CA
T_REM       EQU $EA
; Control codes inside a string or a line: INK, PAPER, FLASH, BRIGHT (each followed by its value)
C_INK       EQU $10
C_PAPER     EQU $11
C_FLASH     EQU $12
C_BRIGHT    EQU $13
C_INVERSE   EQU $14

; ROM addresses the stub uses
ERR_SP      EQU $5C3D           ; the address an error returns to
LD_BYTES    EQU $0556           ; the ROM's LD-BYTES, copied to SoftLoader
SoftLoader  EQU $FF00           ; the copy, patched: the Softlock loader (03 3.4)
Screen      EQU $4000

; The sum of the screen the BASIC leaves, $4000-$5BFF as 3584 big-endian words (c1 frame 774; 03 3.3)
ScreenKey   EQU $CA4E

; A number as the ROM stores it after its digits: $0E and the 5-byte small integer form
  MACRO NUM text, value
    DB text
    DB $0E, 0, 0, low(value), high(value), 0
  ENDM

Basic:
  DB 0, 0                       ; line 0 (the number is big-endian)
  DW Line0End-Line0
Line0:
  DB C_PAPER, C_INVERSE, C_INK, 7   ; colour codes ahead of the first keyword: LIST prints the line in other colours
  DB T_BORDER
  NUM "0", 0
  DB ":", T_INK
  NUM "0", 0
  DB ":", T_PAPER
  NUM "7", 0                    ; PAPER 7 shown, PAPER 0 done
  DB ":", T_CLS, ":", T_PRINT, T_AT
  NUM "12", 21                  ; AT 12 shown, AT 21 done: the bottom line
  DB ","
  NUM "11", 11
  DB ";", '"', C_PAPER, 1, C_INK, 1, "*", C_INK, 7, "LOADING", C_INK, 1, "*", C_INK, 0, C_PAPER, 7, '"'
  DB C_INK, 7
  DB ":", T_POKE
  NUM "23613", 20107            ; ERR_SP shown; one byte of pixels at $4E8B done
  DB ","
  NUM "0", 255
  DB ":", T_RANDOMIZE, T_USR, "(", T_PEEK
  NUM "23627", 23627            ; VARS
  DB "+"
  NUM "256", 256
  DB "*", T_PEEK
  NUM "23628", 23628
  DB ")", $0D
Line0End:
  DB 0, 1
  DW Line1End-Line1
Line1:
  DB T_SAVE, '"E L I T E"', T_LINE
  NUM "0", 0
  DB $0D
Line1End:
  DB 0, 2
  DW Line2End-Line2
Line2:
  DB " ", T_REM, "*** SOFTLOCKtm ", $7F, "1984 ***", $0D   ; a space before REM; $7F: the copyright sign
Line2End:

; ---------------------------------------------------------------------------------------------------------------
; The stub at VARS ($5D93). USR leaves its own address in BC and A = C.
Stub:
  LD IYL,A                      ; IY is set again before any use
  DEC SP
  DEC SP
  POP BC                        ; BC = Stub: the address USR left below SP
  LD HL,$0000
  PUSH HL
  POP IX
  LD A,$2E
  LD IXH,high Screen            ; IX = $4000
  SLA A                         ; A = $5C, the page the sum stops at
StubSum:
  LD D,(IX+0)
  LD E,(IX+1)
  INC IX
  INC IX
  ADD HL,DE                     ; HL = the sum of the words, big-endian
  CP IXH
  JR NZ,StubSum
  EX DE,HL                      ; DE = the key
  LD HL,StubTail-Stub
  ADD HL,BC                     ; HL = StubTail
  LD IXH,B
  LD IXL,C                      ; IX = Stub
  LD C,$32                      ; the chain starts at $32
StubDecrypt:
  LD A,(HL)
  XOR E
  ADD A,C
  LD (HL),A                     ; byte = (byte XOR key low) + chain
  LD C,A
  INC HL
  INC DE
  LD A,(HL)
  XOR D
  ADD A,C
  LD (HL),A                     ; byte = (byte XOR key high) + chain
  LD C,A
  INC HL
  INC DE
  CP $48                        ; until a pair ends in $48 (StubEnd)
  LD A,A
; From here to StubEnd the tape holds the bytes encrypted: the first pair is this JR NZ itself.
StubTail:
  JR NZ,StubDecrypt
  LD SP,$0000
  LD (ERR_SP),SP                ; an error now jumps to 0: a reset
  LD HL,LD_BYTES
  LD DE,SoftLoader
  LD B,H
  LD C,L
  LDIR                          ; $0556 bytes: past $FFFF the copy writes into the ROM, which keeps nothing
  LD H,high SoftLoader
  LD DE,StubScales-Stub
  ADD IX,DE
  PUSH IX
  POP DE                        ; DE = StubScales
  LD B,StubPokes-StubScales
StubScale:
  LD A,(DE)
  LD L,A
  LD A,(HL)
  SRL (HL)
  SRL (HL)
  SUB (HL)
  LD (HL),A                     ; v = v - v / 4: the timing constants for the faster bits
  INC DE
  DJNZ StubScale
  LD B,(StubEnd-StubPokes)/2
StubPoke:
  LD A,(DE)
  INC DE
  LD L,A
  LD A,(DE)
  INC DE
  LD (HL),A                     ; (SoftLoader + offset) = value
  DJNZ StubPoke
  XOR A
  LD L,A                        ; HL = SoftLoader
  DEC A                         ; A = $FF, the flag
  LD IX,Screen
  LD DE,$1C00                   ; the turbo block: the screen and the chunk reader, $4000-$5BFF
  SCF                           ; load, not verify
  JP (HL)
; The low bytes of the five timing constants of the copy that StubScale shortens by a quarter: the bits are 21 %
; shorter than a ROM block's (03 3.1)
StubScales:
  DB $50                        ; $FF4F LD B,$B0 -> $84: the first bit's timing constant
  DB $71                        ; $FF70 LD B,$B2 -> $86: each later byte's
  DB $79                        ; $FF78 LD A,$CB -> $99: the threshold between a 0 and a 1
  DB $7E                        ; $FF7D LD B,$B0 -> $84: each later bit's
  DB $92                        ; $FF91 LD A,$16 -> $11: the delay before an edge is looked for
; 23 (low byte, value) pokes into the copy (03 3.4); $FFF0, past the routine, gets 0 three times
StubPokes:
  DB $8E, $91, $8F, $FF         ; $FF8D: CALL $FF91, the copy's LD-EDGE-1, in place of the ROM's $05E7
  DB $73, $80                   ; $FF72: LD L,$80 in place of LD L,$01: the marker bit for RR L
  DB $7C, $1D                   ; $FF7B: RR L in place of RL L: each byte arrives bit 0 first
  DB $75, $8D, $76, $FF         ; $FF74: CALL $FF8D, the copy's LD-EDGE-2
  DB $09, $00, $0A, $5B         ; $FF08: LD HL,$5B00 in place of $053F: every block returns into the chunk reader
  DB $80, $74, $81, $FF         ; $FF7F: JP NC,$FF74: the bit loop stays in the copy
  DB $F0, $00, $F0, $00, $F0, $00
  DB $17, $91, $18, $FF         ; $FF16: CALL $FF91
  DB $26, $8D, $27, $FF         ; $FF25: CALL $FF8D
  DB $2D, $8D, $2E, $FF         ; $FF2C: CALL $FF8D
  DB $3C, $91, $3D, $FF         ; $FF3B: CALL $FF91
  DB $46, $91, $47, $FF         ; $FF45: CALL $FF91
StubEnd:
  DB $48, $48                   ; the pair that stops StubDecrypt
  DS 8                          ; to the end of the block, never encrypted

  SAVEBIN "basic-plain.bin",Basic,$-Basic
