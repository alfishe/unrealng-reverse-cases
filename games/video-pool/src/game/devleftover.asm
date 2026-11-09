; --------------------------------------------------------------------------------------------------------------------
; devleftover.asm: Code of the development system left in the image: never run, never read
;
; $E014-$E0FF is Z80 code that no build executes or reads, followed by zeros to the block's end $E1A7. Its CALLs and
; data addresses ($44C1, $4200, $506B, $507E, $50A4, $50B2, $5100, $51CC) point into the 48K's display file, so it was
; assembled for another memory layout. Two pieces: $E014-$E052 counts the zero bits of a bitmap (a free-space count,
; the shape of a disk's allocation map), and from $E056 an assembler-style text scanner: a case-folding compare, an
; is-alphanumeric test, a lookup of a name in a table of 8-byte entries (6 characters and a word) and a parser of a
; parenthesised list of names. With the CALL targets taken as $8FBF bytes below the code ($50A4 = DevIsAlnum $E063,
; $50B2 = DevLookup $E071) the second piece fits its own calls.
; --------------------------------------------------------------------------------------------------------------------

; Development leftover: count the zero bits of the bitmap at $5100 ($51CC + 35
; bytes), store (n + 2) / 4
;
; Starts mid-routine (BIT 5,(IY+4), POP BC without a PUSH). DE = the number of
; 0 bits in ($51CC) + 35 bytes from $5100 (SCF / RRA until $FF); then CALL
; $44C1 and the count + 2, divided by 4, stored at (HL). Never executed or read
; in any build (l1sum.py --reads E014-E1A7).
DevFreeCount:
  BIT 5,(IY+$04)
  JR Z,DevFreeCountBody
  ADD A,A
DevFreeCountBody:
  POP BC
  CALL Screen+4222
  INC HL
  PUSH HL
  LD HL,Screen+4352
  LD DE,$0000
  LD A,(Screen+4556)
  ADD A,$23
  LD B,A
DevFreeByteLoop:
  LD A,(HL)
DevFreeBitLoop:
  SCF
  RRA
  JR C,DevFreeBitNext
  INC DE
DevFreeBitNext:
  CP $FF
  JR NZ,DevFreeBitLoop
  INC L
  DJNZ DevFreeByteLoop
  EX DE,HL
  POP BC
  POP AF
  CALL Screen+1217
  LD H,B
  LD D,L
  LD L,C
  LD E,A
  INC DE
  INC DE
  SRL D
  RR E
  SRL D
  RR E
  LD (HL),E
  INC HL
  LD (HL),D
  XOR A
  RET

; Three bytes ($50, $13, $18) and an endless JR -2 ($FE): no routine start
; found
DevFragment:
  DEFB $50,$13,$18

; Development leftover: compare A with (HL), letters case-folded (RES 5 from
; "A" up)
;
; Never executed.
DevCompareChar:
  CP $41
  JR C,DevCompareFolded
  RES 5,A
DevCompareFolded:
  CP (HL)
  RET

; Development leftover: A = C with Z set (LD A,0; OR A; LD A,C)
;
; Never executed.
DevResultC:
  LD A,$00
  OR A
  LD A,C
  RET

; Development leftover: carry clear for 0-9, A-Z (the $50A4 of the second
; piece)
;
; Never executed.
DevIsAlnum:
  CP $30
  RET C
  CP $3A
  JR C,DevIsAlnumEnd
  CP $41
  RET C
  CP $5B
DevIsAlnumEnd:
  CCF
  RET

; Development leftover: find the name at DE in the table at BC (8-byte entries,
; 0 end); C = index, DE = the word at +6
;
; Compares the first character, then DevMatchName $E088 for five more (a name
; ends at CR, $03 or a non-alphanumeric character, padded with spaces). Never
; executed.
DevLookup:
  PUSH HL
  LD H,B
  LD L,C
  LD C,$01
DevLookupLoop:
  LD A,(DE)
  CP (HL)
  JR Z,DevMatchName
; This entry point is used by the routine at DevMatchName.
DevLookupNext:
  PUSH BC
  LD BC,$0008
  ADD HL,BC
  POP BC
  INC C
  LD A,(HL)
  OR A
  JR NZ,DevLookupLoop
  POP HL
  INC A
  RET

; Development leftover: the rest of a table name (5 characters); found: DE =
; the entry's word, Z
;
; Never executed.
DevMatchName:
  LD B,$05
  PUSH HL
  PUSH DE
DevMatchLoop:
  INC DE
  INC HL
  LD A,(DE)
  CP $03
  JR Z,DevMatchEnd
  CP $0D
  JR Z,DevMatchEnd
  CP (HL)
  JR NZ,DevMatchDiffer
  DJNZ DevMatchLoop
DevMatchFound:
  POP DE
  LD A,C
  POP BC
  LD HL,$0006
  ADD HL,BC
  LD C,A
  LD E,(HL)
  INC HL
  LD D,(HL)
  POP HL
  XOR A
  RET
DevMatchDiffer:
  CALL Screen+4260
  JR NC,DevMatchFail
DevMatchEnd:
  LD A,(HL)
  CP $20
  JR Z,DevMatchFound
DevMatchFail:
  POP DE
  POP HL
  JR DevLookupNext

; Development leftover, kept as bytes: skip spaces; "(" name [, name] ")" with
; each name looked up ($50B2) in the table at DE
;
; Code, never executed, kept as bytes because its last instruction (XOR A at
; $E0FF) runs on into the zeros at $E100 and a branch (JR Z at $E0E7) jumps to
; $E101: the piece is cut off there. Disassembled: $E0B8 INC HL; LD A,(HL); CP
; $0D; RET Z; CP " "; JR Z,$E0B8; CP "("; JR NZ,$E0FF. $E0C5 PUSH DE; LD B,6;
; LD DE,$4200; INC HL; CALL $506B (read a name of up to six characters into
; $4200); DEC HL; POP DE; RET NZ; CP $0D; JR NZ,$E0D7; INC HL. $E0D7 PUSH DE;
; LD B,D; LD C,E; LD DE,$4200; CALL $50B2 (DevLookup's address in the piece's
; own layout); JR Z,$E0E4; POP DE; RET. $E0E4 LD A,(HL); CP "="; JR Z,$E101; LD
; BC,$FFFF; LD (DE),C; INC DE; LD (DE),B (stored through DE as two LD (DE),A);
; POP DE; LD A,(HL); CP ","; JR Z,$E0C5; CP $0D; JR Z,$E0FF; CP ")"; RET NZ;
; INC HL. $E0FF XOR A, then the zeros.
DevParseList:
  DEFB $23,$7E,$FE,$0D,$C8,$FE,$20,$28
  DEFB $F7,$FE,$28,$20,$3A,$D5,$06,$06
  DEFB $11,$00,$42,$23,$CD,$6B,$50,$2B
  DEFB $D1,$C0,$FE,$0D,$20,$01,$23,$D5
  DEFB $42,$4B,$11,$00,$42,$CD,$B2,$50
  DEFB $28,$02,$D1,$C9,$7E,$FE,$3D,$28
  DEFB $18,$01,$FF,$FF,$79,$12,$13,$78
  DEFB $12,$D1,$7E,$FE,$2C,$28,$CE,$FE
  DEFB $0D,$28,$04,$FE,$29,$C0,$23,$AF

; Zeros to the end of the loaded block ($E1A7)
DevZeros:
  DEFS $A8
