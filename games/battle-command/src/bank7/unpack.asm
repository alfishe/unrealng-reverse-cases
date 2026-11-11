; --------------------------------------------------------------------------------------------------------------------
; unpack.asm: UnpackPicture: a packed screen from bank 7 onto the screen
;
; The format: tools/bank7pic.py. A block is the size word, the unpacked length ($1B00), 16 common bytes, the number of
; extra offset bits, then a bit stream read least significant bit first. Each token opens with 2 bits: 01 a literal
; byte, 11 one of the 16 common bytes, 10 a copy of earlier output (count, offset up to 511), 00 a run of one byte
; (literal or common). The routine keeps its state in its own operands (self-modifying code).
; --------------------------------------------------------------------------------------------------------------------

; UnpackPicture's pointers: $FE8F and $FE93 the common-byte table, $FE91 the
; bit stream
;
; Written by UnpackPicture `$FEA7`-`$FEB6`; `$FE93` is read for every common
; byte (`$FEF0`, `$FF70`), `$FE91` by StartBits; `$FE8F` is written and never
; read (known only from the code). Zero in the image.
UnpackVars:
  DEFB $00,$00
StreamPtr:
  DEFB $00,$00
TablePtr:
  DEFB $00,$00

; Unpack the block at DE onto the screen from $4000, then set BRIGHT in every
; attribute
;
; Input: DE = a block of bank 7 (paged at `$C000`). Output: `$4000-$5AFF` the
; screen; BC, DE, HL, AF and the alternate set changed.
;
; Clears the output count (`$FF9F`), takes the unpacked length into the compare
; at `$FEC5`, the table and stream addresses into UnpackVars, the extra offset
; bits into `$FF43`, the output pointer `$FF97` = `$4000`, the first byte
; through StartBits; then a token at a time (`$FECF`): 2 bits by GetBits, the
; type kept in `$FF36`. 01: 8 bits to PutByte. 11: 4 bits, the table's byte
; `NOT n AND $0F`. 0x: a count of 6 bits (0: 7 more bits, 1: 8 bits, 2: 8 + 6
; bits); type 10 then an offset of 8 bits plus the extra bits, and the count
; bytes from output - offset; type 00 a bit: the run byte from the table (4
; bits) or 8 bits, stored into `$FF8A`, count times. When the count reaches the
; length, `JP BrightenAttributes`.
;
; Witness: L1 120 (c1, death, m10, m2erbe, m2ocean, menu, missions, play,
; play2, search).
UnpackPicture:
  LD BC,$0000
  LD (WrittenCountOp+$0001),BC
  EX DE,HL
  INC HL
  INC HL
  LD C,(HL)
  INC HL
  LD B,(HL)
  INC HL
  LD (LengthOp+$0001),BC
  LD (TablePtr),HL
  LD (UnpackVars),HL
  LD DE,$0010
  ADD HL,DE
  LD A,(HL)
  LD (LongBitsOp+$0001),A
  INC HL
  LD (StreamPtr),HL
  LD HL,$4000
  LD (PutByte+$0001),HL
  CALL StartBits
NextToken:
  LD HL,(WrittenCountOp+$0001)
LengthOp:
  LD BC,$0000             ; LD BC,n: n ($FEC6) the unpacked length
  SBC HL,BC
  JR C,l_FECF
  JP BrightenAttributes
l_FECF:
  LD A,$02
  CALL GetBits
  AND $03
  LD (TokenTypeOp+$0001),A
  BIT 0,A
  JR Z,CountedToken
  BIT 1,A
  JR NZ,TableByte
  LD A,$08
  CALL GetBits
  CALL PutByte
  JR NextToken
TableByte:
  LD A,$04
  CALL GetBits
  LD HL,(TablePtr)
  CPL
  AND $0F
  LD C,A
  LD B,$00
  ADD HL,BC
  LD A,(HL)
  CALL PutByte
  JR NextToken
CountedToken:
  LD A,$06
  CALL GetBits
  LD B,$00
  AND $3F
  LD C,A
  CP $03
  JR NC,TokenTypeOp
  AND A
  JR NZ,l_FF1B
  LD A,$07
  CALL GetBits
  AND $7F
  LD C,A
  JR TokenTypeOp
l_FF1B:
  CP $01
  JR NZ,l_FF27
  LD A,$08
  CALL GetBits
  LD C,A
  JR TokenTypeOp
l_FF27:
  LD A,$08
  CALL GetBits
  LD C,A
  LD A,$06
  CALL GetBits
  AND $3F
  LD B,A
TokenTypeOp:
  LD A,$00                ; LD A,n: n ($FF36) the token's 2 type bits
  AND A
  JR Z,RunToken
  LD D,$00
  LD A,$08
  CALL GetBits
  LD E,A
LongBitsOp:
  LD A,$00                ; LD A,n: n ($FF43) the extra offset bits
  AND A
  JR Z,l_FF4D
  CALL GetBits
OffsetMaskOp:
  AND $00                 ; AND n: n ($FF4B) the mask of the extra bits
                          ; (StartBits)
  LD D,A
l_FF4D:
  LD HL,(PutByte+$0001)
  SBC HL,DE
CopyLoop:
  LD A,(HL)
  PUSH HL
  CALL PutByte
  POP HL
  INC HL
  DEC BC
  LD A,B
  OR C
  JR NZ,CopyLoop
  JP NextToken
RunToken:
  LD A,$01
  CALL GetBits
  AND $01
  JR Z,l_FF81
  LD A,$04
  CALL GetBits
  PUSH BC
  LD HL,(TablePtr)
  CPL
  AND $0F
  LD C,A
  LD B,$00
  ADD HL,BC
  LD A,(HL)
  LD (RunByteOp+$0001),A
  POP BC
  JR RunByteOp
l_FF81:
  LD A,$08
  CALL GetBits
  LD (RunByteOp+$0001),A
RunByteOp:
  LD A,$00                ; LD A,n: n ($FF8A) the run's byte
  CALL PutByte
  DEC BC
  LD A,B
  OR C
  JR NZ,RunByteOp
  JP NextToken

; Store A at the output pointer, advance it and count the byte
;
; Input: A. The pointer is the operand at `$FF97`, the count the operand at
; `$FF9F`. Output: HL = the new count.
;
; Witness: L1 829440 (c1, death, m10, m2erbe, m2ocean, menu, missions, play,
; play2, search).
PutByte:
  LD HL,$4000
  LD (HL),A
  INC HL
  LD (PutByte+$0001),HL
WrittenCountOp:
  LD HL,$0000             ; LD HL,n: n ($FF9F) the bytes written so far
  INC HL
  LD (WrittenCountOp+$0001),HL
  RET

; OR $40 (BRIGHT) into the 768 attributes $5800-$5AFF
;
; Every picture is shown bright; the blocks themselves keep BRIGHT off.
; Witness: L1 120 (c1, death, m10, m2erbe, m2ocean, menu, missions, play,
; play2, search).
BrightenAttributes:
  LD HL,$5800
  LD BC,$0300
l_FFAC:
  LD A,(HL)
  OR $40
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JR NZ,l_FFAC
  RET

; Return the next A bits of the stream in A (low bits first), using the
; alternate set
;
; Input: A = 1-8. The alternate DE holds the bits not yet taken, HL' the next
; stream byte; the number of bits left in E' is the operand at `$FFBD`. When
; fewer are left than asked, the next byte goes into D' and DE' shifts right as
; far as the bits taken. Output: A = E' before the shift (the caller masks it).
; Witness: L1 359432 (c1, death, m10, m2erbe, m2ocean, menu, missions, play,
; play2, search).
GetBits:
  EXX
  LD C,A
  LD B,A
  LD A,E
  PUSH AF
BitsLeftOp:
  LD A,$00                ; LD A,n: n ($FFBD) the bits left in E'
  CP C
  JR NC,l_FFD3
  AND A
  JR Z,l_FFCD
  LD B,A
l_FFC5:
  SRL D
  RR E
  DJNZ l_FFC5
  NEG
l_FFCD:
  ADD A,C
  LD B,A
  LD D,(HL)
  INC HL
  LD A,$08
l_FFD3:
  SUB B
  LD (BitsLeftOp+$0001),A
l_FFD7:
  SRL D
  RR E
  DJNZ l_FFD7
  POP AF
  EXX
  RET

; Set the offset mask from A (the extra bits) and load the stream's first byte
; into E'
;
; Input: A = the extra offset bits. `$FF4B` = BitMasks + A, HL' = the stream
; (`$FE91`) and E' its first byte, `$FFBD` = 0. Witness: L1 120 (c1, death,
; m10, m2erbe, m2ocean, menu, missions, play, play2, search).
StartBits:
  EXX
  LD C,A
  LD B,$00
  LD HL,BitMasks
  ADD HL,BC
  LD A,(HL)
  LD (OffsetMaskOp+$0001),A
  LD HL,(StreamPtr)
  LD E,(HL)
  INC HL
  XOR A
  LD (BitsLeftOp+$0001),A
  EXX
  RET

; The masks of 0-7 low bits: $00, $01, $03 ... $7F
;
; Read by StartBits.
BitMasks:
  DEFB $00,$01,$03,$07,$0F,$1F,$3F,$7F
  DEFB $00
