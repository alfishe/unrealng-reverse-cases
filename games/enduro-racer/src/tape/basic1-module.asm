; --------------------------------------------------------------------------------------------------------------------
; basic1-module.asm: The first BASIC: colours, USR into Stage0, LOAD ""
;
; Line 0: PAPER 0: INK 0: BORDER 0: CLS: PRINT USR 6746931: LOAD "". The digits say 6746931; the hidden number is
; 23829 ($5D15, Stage0). Stage0 copies the bytes behind it to $FF98 and sets ERR_SP to $FFFA, so the error the second
; BASIC ends with is caught there. The second line, number 65152 with a length of 65535, is no line: the bytes after
; the end of the first, Stage0's code and its data, which LIST shows as junk.
; --------------------------------------------------------------------------------------------------------------------

; Line 0: PAPER 0: INK 0: BORDER 0: CLS: PRINT USR "6746931" (23829): LOAD ""
;
; The line number high byte first, the length (53) low byte first, the tokens,
; $0D. Read by the ROM's interpreter in c1; no machine code reads it.
BasicLine0:
  DEFB $00,$00,$35,$00,$11,$07,$10,$07
  DEFB $DA,$30,$0E,$00,$00,$00,$00,$00
  DEFB $3A,$D9,$30,$0E,$00,$00,$00,$00
  DEFB $00,$3A,$E7,$30,$0E,$00,$00,$00
  DEFB $00,$00,$3A,$FB,$3A,$F5,$C0,$36
  DEFB $37,$34,$36,$39,$33,$31,$0E,$8F
  DEFB $3A,$2A,$33,$33,$3A
BasicLine1:
  DEFB $EF,$22,$22,$0D,$FE,$80,$FF,$FF ; the bytes after line 0: number 65152,
  DEFB $11,$07,$10,$07,$EA             ; length 65535 (LIST stops at the end of
                                       ; the program)
StubBytes:
  DEFB $F3,$E5,$F5,$D9,$CD,$14,$5B,$C9 ; DI / PUSH HL / PUSH AF / EXX / CALL
                                       ; $5B14 / RET: bytes LIST shows, unused
                                       ; by Stage0

; CALL Stage0Copy: its return address is the source of the copy
;
; Entered by PRINT USR 23829. The CALL pushes $5D18, which Stage0Copy POPs as
; the copy's source.
;
; Witness: L1 1 (c1).
Stage0:
  CALL Stage0Copy
  EXX
  PUSH AF

; Copy $5D18-$5D80 to $FF98-$FFFF, set ERR_SP to $FFFA and I, return to BASIC
;
; Obfuscated with IXL/IXH moves and both register sets (known from the code;
; the result is in the c1 dump at frame 1574). Interrupts off; POP BC' takes
; $5D18; SP = $FFF8; RES 4,(IY+1) (FLAGS bit 4, the 128K ROM's mode flag); R =
; $A6, I = $3F; ERR_SP ($5C3D) = $FFFA; the 105 bytes $5D18-$5D80 go to
; $FF98-$FFFF. The copy leaves $1B76 (the ROM's STMT-RET) at $FFF8, which the
; RET takes back to the interpreter, and $1303 (MAIN-4, the error return) at
; $FFFA until the second BASIC pokes VARS there. The interpreter then runs LOAD
; "" for the second BASIC.
;
; Witness: L1 1 (c1).
Stage0Copy:
  LD IXL,$00
  LD C,$FA
  LD A,IXH
  DI
  LD B,$87
  EXX
  DEC IXL
  AND $34
  DAA
  LD E,IXL
  POP BC
  LD A,$F8
  LD IXH,IXL
  LD D,$5C
  EXX
  LD D,C
  LD IXL,A
  LD A,$1E
  LD SP,IX
  ADD A,B
  RES 4,(IY+$01)
  LD L,$24
  EXX
  LD IXL,E
  INC A
  LD E,$3E
  LD R,A
  EXX
  XOR $99
  LD IXH,D
  LD D,IXL
  LD E,$3D
  LD I,A
  LD A,IXH
  LD (IY+$03),A
  LD IXL,$98
  LD A,D
  EXX
  LD (DE),A
  LD A,$FF
  LD E,$69
  LD IXH,A
l_5D66:
  LD A,(BC)               ; the copy loop, 105 bytes
  LD (IX+$00),A
  INC BC
  INC IX
  DEC E
  JP NZ,l_5D66
  EXX
  EI
  RET

; The copy's tail: at $FFF8 the return $1B76, at $FFFA the error return $1303
Stage0Data:
  DEFB $10,$1C,$52,$1B,$76,$1B,$03,$13
  DEFB $00,$3E,$00,$00,$30
BasicTail:
  DEFB $30,$30,$30,$0D,$EE,$00,$00,$47 ; past the copy: the rest of the 205
  DEFB $5D,$00,$00,$00,$C0,$5D,$00,$00 ; bytes, never read
  DEFB $00,$01,$00,$00,$F4,$01,$02
