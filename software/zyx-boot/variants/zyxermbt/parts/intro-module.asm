; --------------------------------------------------------------------------------------------------------------------
; intro-module.asm: Unpack a picture onto the screen while the menu loads
;
; The loader calls IntroPicture at $7530 with the screen cleared; it returns with the picture on the screen and the
; loader then reads the menu, fades the picture (its routine at $5DE7) and calls the menu. The routine is position
; independent: it finds its own address and writes the address of PutByte into its three CALLs, which hold $74A6 on
; the disk (the address it was assembled at).
; --------------------------------------------------------------------------------------------------------------------

; Find our address, point the three CALLs at PutByte, unpack PackedScreen to
; Screen $4000 in the screen's third-row-column order
;
; The packed stream: a byte with bit 7 clear is a copy of 3-18 bytes from
; earlier output (bits 3-6 the length - 3, bits 0-2 and the next byte the
; distance back); $80+n copies n literal bytes; $C0+n repeats the next byte n+3
; times; $80 ends.
IntroPicture:
  DI
  CALL RomRet
  DEC SP                  ; BC = our address + 4
  DEC SP
  POP BC
  LD HL,$0097
  ADD HL,BC
  EX DE,HL
  LD HL,$0066
  ADD HL,BC
  LD (HL),E
  INC HL
  LD (HL),D
  LD HL,$007B
  ADD HL,BC
  LD (HL),E
  INC HL
  LD (HL),D
  LD HL,$0089
  ADD HL,BC
  LD (HL),E
  INC HL
  LD (HL),D
  LD HL,$00BE             ; HL = PackedScreen; the output position in DE' and
                          ; the row counters
  ADD HL,BC
  LD DE,Screen
  PUSH DE
  EXX
  EX AF,AF'
  LD A,$03
  OR A
  LD B,$08
  LD C,B
  POP HL
  EX AF,AF'
  EXX
UnpackLoop:
  LD A,(HL)               ; the next control byte
  BIT 7,A
  JR NZ,UnpackLiteral
  AND $07
  LD C,A
  LD A,(HL)
  RRCA
  RRCA
  RRCA
  AND $0F
  ADD A,$03
  LD B,A
  INC HL
  LD A,E
  SUB (HL)
  INC HL
  PUSH HL
  LD L,A
  LD A,D
  SBC A,C
  LD H,A
l_757E:
  PUSH HL
  LD A,H
  AND $58
  CP $58
  JR Z,l_7598
  LD C,A
  LD A,L
  AND $07
  OR C
  LD C,A
  ADD HL,HL
  ADD HL,HL
  LD A,H
  AND $1F
  LD H,A
  LD A,L
  AND $E0
  OR H
  LD L,A
  LD H,C
l_7598:
  LD A,(HL)
  CALL $74A6
  POP HL
  INC HL
  DJNZ l_757E
  POP HL
  JR UnpackLoop
UnpackLiteral:
  AND $7F                 ; $80-$FF: literals or a run; $80 alone ends
  JR Z,l_75C4
  INC HL
  BIT 6,A
  JR NZ,l_75B6
  LD B,A
l_75AD:
  LD A,(HL)
  CALL $74A6
  INC HL
  DJNZ l_75AD
  JR UnpackLoop
l_75B6:
  AND $3F
  ADD A,$03
  LD B,A
  LD A,(HL)
l_75BC:
  CALL $74A6
  DJNZ l_75BC
  INC HL
  JR UnpackLoop
l_75C4:
  EXX                     ; done: HL' back to the ROM's value for BASIC
  LD HL,$2758
  EXX
  EI
  RET

; Store A at the output position and step it in the screen's order (8 pixel
; rows a cell, then the next cell, then the next third)
PutByte:
  INC DE
  EXX
  LD (HL),A
  EX AF,AF'
  JR Z,l_75EA
  INC H
  DJNZ l_75EF
  LD DE,$F820
  ADD HL,DE
  DEC C
  JR NZ,l_75ED
  LD DE,$FF01
  ADD HL,DE
  ADD A,$08
  JR NC,l_75EB
  LD DE,$07E0
  ADD HL,DE
  DEC A
  JR l_75EB
l_75EA:
  INC HL
l_75EB:
  LD C,$08
l_75ED:
  LD B,$08
l_75EF:
  EX AF,AF'
  EXX
  RET

; The packed picture (the screen and its attributes), up to its end mark
; (tools/res_screens.py packs it from its PNG)
PackedScreen:
  INCBIN "res/graphics/intro-picture.bin",$0000,547

; zeros to the third sector's end
IntroEnd:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
