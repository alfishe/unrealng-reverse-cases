; --------------------------------------------------------------------------------------------------------------------
; text.asm: The screen text and attribute primitives: the print engine with control codes
;
; PrintString $6FB3 interprets a string: a byte below $20 is a control code through the table $6F8F (position, colour,
; numbers, attribute boxes), $20-$81 a character (the 8x8 font of bank 6 at $F5E4, from $20), $82 and above a token (a
; string through the word table at $9860), $FF the end. The second font, 5 bytes a glyph from "0" (SmallFont $7C59),
; is printed by $6DE8 at any pixel column.
; --------------------------------------------------------------------------------------------------------------------

  ORG $6CE4

; Seven zero bytes (NOP) before BorderBlack: room for a patch
PatchSpace:
  DEFB $00,$00,$00,$00,$00,$00,$00

; Border 0 (the stored colour $6CF1 cleared)
;
; Witness: L1 66 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2,
; search).
BorderBlack:
  PUSH AF
  XOR A
  JR l_6CF4

; BorderNext
BorderNext:
  DEFB $F5,$3E,$00,$C6,$01 ; the border one colour on (a debug aid, known only
                           ; from the code)

; l_6CF4
;
; Used by the routine at BorderBlack.
l_6CF4:
  LD (BorderNext+$0002),A
  OUT ($FE),A
  POP AF
  RET

; Fill an attribute box from a 5-byte record: width, height, column, attribute,
; row
;
; HL -> B (width), C (height), E (column), A (attribute), L (row); falls into
; AttrBoxAt. Witness: L1 350 (c1, death, m10, m2erbe, m2ocean, menu, missions,
; play, play2, search).
AttrBox:
  LD B,(HL)
  INC HL

; AttrBox with B already set (HL -> height, column, attribute, row)
;
; Witness: L1 319 (c1, death, m10, m2erbe, m2ocean, menu, missions, play,
; play2, search).
AttrBoxAt:
  LD C,(HL)

; AttrBoxAtC
;
; Used by the routine at SkyColours.
AttrBoxAtC:
  INC HL
  LD E,(HL)
  INC HL
  LD A,(HL)
  INC HL
  EX AF,AF'
  LD L,(HL)

; Fill C rows of B attribute bytes with A' from row L, column E ($5800 + 32L +
; E)
;
; Witness: L1 70 (c1, menu, missions, play, play2).
AttrBoxRC:
  LD H,$00
  LD D,H
  CALL LowTimes32
  ADD HL,DE
  LD DE,$5800
  ADD HL,DE
  LD DE,$0020
  LD A,B
l_6D14:
  PUSH HL
  EX AF,AF'
  LD B,A
  EX AF,AF'
l_6D18:
  LD (HL),A
  INC L
  DJNZ l_6D18
  POP HL
  ADD HL,DE
  DEC C
  JR NZ,l_6D14
  RET

; Fill E pixel lines of D bytes with A from the line table $6500, column C
;
; Uses the line address table at `$6500` (2 bytes a pixel line). Witness: L1
; 200 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).
ScreenRowFill:
  LD B,D
  EXX
  LD H,$00
  LD B,H
  LD E,H
  LD L,A
  ADD HL,HL
  LD D,$65
  ADD HL,DE
  EX AF,AF'
l_6D2E:
  LD E,(HL)
  INC HL
  LD D,(HL)
  EX DE,HL
  ADD HL,BC
  PUSH HL
  EXX
  POP HL
l_6D36:
  LD (HL),A
  INC L
  DJNZ l_6D36
  DEC E
  RET Z
  LD B,D
  EXX
  EX DE,HL
  INC HL
  JR l_6D2E

; When the pointer is clicked, call the zone of the current screen that holds
; the pointer
;
; `LD A,n`: n (`$6D43`) is set by the fire test of the interrupt (`$7DC2`). The
; zone table (HL, the operand at `$6D47`, set per screen by `SetScreen`
; `$7060`) has 6-byte records x1, x2, y1, y2 and a routine; the first record
; with x1 <= X < x2 and y1 <= Y < y2 (X `$9715`, Y `$9716`) is called. A 0 byte
; ends the table. Witness: L1 30082532 (c1, controls, death, m10, m2erbe,
; m2ocean, menu, missions, play, play2, search).
PointerZones:
  LD A,$00
  AND A
  RET Z
  LD HL,l_C4DB+$000E
l_6D49:
  LD A,(HL)
  AND A
  JR Z,l_6D7A
  PUSH HL
  LD A,(ClickX)
  LD C,(HL)
  CP C
  JR C,l_6D73
  INC HL
  LD C,(HL)
  CP C
  JR NC,l_6D73
  INC HL
  LD A,(ClickY)
  LD C,(HL)
  CP C
  JR C,l_6D73
  INC HL
  LD C,(HL)
  CP C
  JR NC,l_6D73
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD (l_6D49+$0028),DE
  CALL $0000
l_6D73:
  POP HL
  LD BC,$0006
  ADD HL,BC
  JR l_6D49
l_6D7A:
  XOR A
  LD (PointerZones+$0001),A
  RET

; Copy a C x B graphic from HL' to the screen at pixel line A, column BC
;
; The line address table `$6500` again. Witness: L1 416 (c1, death, m10,
; m2erbe, m2ocean, menu, missions, play, play2, search).
CopyGraphic:
  LD D,$00
  LD B,D
  LD HL,ScreenRowTable
  SLA A
  RL D
  LD E,A
  ADD HL,DE
l_6D8B:
  LD E,(HL)
  INC HL
  LD D,(HL)
  EX DE,HL
  ADD HL,BC
  EXX
  LD B,D
l_6D92:
  LD A,(HL)
  INC HL
  EXX
  LD (HL),A
  INC HL
  EXX
  DJNZ l_6D92
  DEC C
  RET Z
  EXX
  EX DE,HL
  INC HL
  JR l_6D8B

; Control code 7: switch to the small font, then CodeAt
;
; Witness: L1 1122 (c1, death, m10, m2erbe, m2ocean, menu, missions, play,
; play2, search).
CodeSmallFont:
  CALL CodeSmallAt
  JR l_6DA7

; Control code 5: the small font's column (6-pixel cells) from the next byte;
; the font is not switched
;
; Witness: known only from the code (no string of the recordings uses code 5).
CodeSmallChars:
  EXX
; This entry point is used by the routine at CodeSmallFont.
l_6DA7:
  LD A,(HL)
  INC HL

; A = column in 6-pixel cells: the byte ($6DFD) and the bit shift ($6DEC)
;
; Witness: L1 1423 (c1, death, m10, m2erbe, m2ocean, menu, missions, play,
; play2, search).
SmallFontColumn:
  ADD A,A
  LD C,A
  ADD A,A
  ADD A,C
  LD C,A
  AND $07
  LD (PrintSmallChar+$0004),A
  SRL C
  SRL C
  SRL C
  LD B,$00
  LD (PrintSmallChar+$0015),BC
  RET

; The next 6-pixel cell, a new line past column 32
;
; Witness: L1 17639 (c1, death, m10, m2erbe, m2ocean, menu, missions, play,
; play2, search).
SmallFontAdvance:
  LD A,(PrintSmallChar+$0015)
  CP $20
  JP NC,SmallNewLine
  LD A,(PrintSmallChar+$0004)
  AND A
  JR Z,l_6DD2
  LD HL,PrintSmallChar+$0015
  INC (HL)
l_6DD2:
  SBC A,$02
  AND $07
  LD (PrintSmallChar+$0004),A
  RET

; HL = SmallFont + 5 (A - "0")
;
; Witness: L1 17639 (c1, death, m10, m2erbe, m2ocean, menu, missions, play,
; play2, search).
SmallGlyph:
  SUB $30
  LD C,A
  ADD A,A
  ADD A,A
  ADD A,C
  LD B,$00
  LD C,A
  LD HL,SmallFont
  ADD HL,BC
  RET

; Print a small-font character at the current cell: 5 lines, one of four shifts
; through $6E9F
;
; Witness: L1 17639 (c1, death, m10, m2erbe, m2ocean, menu, missions, play,
; play2, search).
PrintSmallChar:
  LD HL,ShiftRoutines
  LD BC,$0000
  ADD HL,BC
  LD C,(HL)
  INC HL
  LD B,(HL)
  LD (l_6E05+$0001),BC
  EX DE,HL
  EXX
  PUSH HL
  LD HL,$0000
  LD BC,$0000
  EXX
  CALL SmallGlyph
  LD B,$05
l_6E05:
  JP l_6E05
l_6E08:
  EXX
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  EX DE,HL
  ADD HL,BC
  LD A,(HL)
  AND $03
  EXX
  OR (HL)
  INC HL
  EXX
  LD (HL),A
  EX DE,HL
  EXX
  DJNZ l_6E08
l_6E1B:
  CALL SmallFontAdvance
  POP HL
  RET
l_6E20:
  EXX
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  EX DE,HL
  ADD HL,BC
  LD A,(HL)
  AND $FC
  EXX
  LD D,$00
  LD E,(HL)
  INC HL
  SLA E
  RL D
  SLA E
  RL D
  OR D
  EXX
  LD (HL),A
  INC HL
  LD A,(HL)
  AND $0F
  EXX
  OR E
  EXX
  LD (HL),A
  EX DE,HL
  EXX
  DJNZ l_6E20
  JR l_6E1B
l_6E48:
  EXX
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  EX DE,HL
  ADD HL,BC
  EXX
  LD D,$00
  LD E,(HL)
  INC HL
  SLA E
  RL D
  SLA E
  RL D
  SLA E
  RL D
  SLA E
  RL D
  LD A,$0F
  AND D
  LD D,A
  EXX
  LD A,(HL)
  EXX
  AND $F0
  OR D
  EXX
  LD (HL),A
  INC HL
  EXX
  LD A,$C0
  AND E
  LD E,A
  EXX
  LD A,(HL)
  EXX
  AND $3F
  OR E
  EXX
  LD (HL),A
  EX DE,HL
  EXX
  DJNZ l_6E48
  JR l_6E1B
l_6E84:
  EXX
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  EX DE,HL
  ADD HL,BC
  LD A,(HL)
  AND $C0
  EXX
  LD E,(HL)
  SRL E
  SRL E
  OR E
  INC HL
  EXX
  LD (HL),A
  EX DE,HL
  EXX
  DJNZ l_6E84
  JP l_6E1B

; The four shift routines of PrintSmallChar (shift 0, 6, 4, 2 bits)
ShiftRoutines:
  DEFW l_6E08,l_6E84,l_6E48,l_6E20

; Control code 0: the next byte is the column ($6FF8)
;
; Witness: known only from the code (no recording counts it: it is entered by
; the CALL patched at `$6FD6`).
CodeColumn:
  EXX
; This entry point is used by the routine at CodeAtColumn.
l_6EA8:
  LD A,(HL)
  INC HL
  LD (PrintChar+$0008),A
  RET

; Control code 2: a row (CodeAt) then a column
;
; Witness: L1 859 (c1, death, m10, m2erbe, m2ocean, menu, missions, play,
; play2, search).
CodeAtColumn:
  CALL CodeAt
  JR l_6EA8

; Control code 1: the next byte is the character row: its line pointers and
; attribute address
;
; Witness: L1 859 (c1, death, m10, m2erbe, m2ocean, menu, missions, play,
; play2, search).
CodeAt:
  EXX
  LD A,(HL)
  INC HL
  EX DE,HL
  LD H,$00
  LD L,A
  ADD HL,HL
  LD B,H
  LD C,L
  LD HL,ScreenRowTable
  ADD HL,BC
  LD (PrintChar+$000B),HL
  SLA C
  RL B
  LD HL,$5800
  ADD HL,BC
  LD (CodeNewLine+$0010),HL
  LD HL,PrintChar
  LD (PrintString+$000F),HL
  EX DE,HL
  RET

; HL = the 8x8 glyph of character A: $F5E4 + 8 (A - $20) (bank 6)
;
; Witness: L1 6525 (c1, death, m10, m2erbe, m2ocean, menu, missions, play,
; play2, search).
GlyphAddress:
  SUB $20
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  AND A
  LD BC,$F5E4
  ADD HL,BC
  RET

; The column one on, a new line after 31
;
; Witness: known only from the code.
NextColumn:
  LD A,(PrintChar+$0008)
  CP $1F
  JR NC,l_6F4C
  INC A
  LD (PrintChar+$0008),A
  RET

; Control code 8: print the byte at the address that follows as three decimal
; digits
;
; Witness: L1 140 (c1, death, m10, m2erbe, m2ocean, menu, missions, play,
; play2, search).
CodeNumber:
  EXX
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  EX DE,HL
  LD A,(HL)
  EX DE,HL
  JR l_6EFE

; Control code 3: three decimal digits of a constant: LD A,$5E overwrites A, so
; it prints "094"; no string uses it
;
; Witness: known only from the code.
CodeNumberA:
  LD A,$5E
  EXX
; This entry point is used by the routine at CodeNumber.
l_6EFE:
  PUSH HL
  LD HL,NumberText
  LD B,$64
  CALL DivideDigit
  LD B,$0A
  CALL DivideDigit
  AND A
  ADC A,$30
  LD (HL),A
  DEC HL
  DEC HL
  CALL PrintString
  POP HL
  RET

; Control code 4: two hexadecimal digits of the constant $5E (LD A,$5E): "5E";
; no string uses it
;
; Witness: known only from the code.
CodeHex:
  LD A,$5E
  EXX
  PUSH HL
  LD HL,NumberText+$0001
  LD B,$10
  CALL DivideDigit
  CALL DigitChar
  DEC HL
  DEC HL
  CALL PrintString
  POP HL
  RET

; Three digits and $FF: the buffer of CodeNumber
NumberText:
  DEFB $00,$00,$00,$FF

; A / B: C the quotient, A the rest; the digit stored at HL
;
; Witness: L1 280 (c1, death, m10, m2erbe, m2ocean, menu, missions, play,
; play2, search).
DivideDigit:
  LD C,$00
  AND A
l_6F34:
  CP B
  JR C,l_6F3B
  SBC A,B
  INC C
  JR l_6F34
l_6F3B:
  EX AF,AF'
  LD A,C

; DigitChar
;
; Used by the routine at CodeHex.
DigitChar:
  AND A                   ; A (0-15) as a digit or a letter at HL
  CP $0A
  JR C,l_6F46
  ADC A,$37
  JR l_6F48
l_6F46:
  ADC A,$2F
l_6F48:
  LD (HL),A
  INC HL
  EX AF,AF'
  RET
; This entry point is used by the routine at NextColumn.
l_6F4C:
  EXX

; Control code 11: the next character row, column 0
;
; Witness: L1 156 (c1, death, m10, m2erbe, m2ocean, menu, missions, play,
; play2, search).
CodeNewLine:
  LD HL,(PrintChar+$000B)
  LD BC,$0010
  ADD HL,BC
  LD (PrintChar+$000B),HL
  LD A,$00
  LD (PrintChar+$0008),A
  LD HL,$0000
  LD C,$20
  ADD HL,BC
  LD (CodeNewLine+$0010),HL
  EXX
  RET

; Control code 10: the small font's next line (9 pixel lines down:
; ScreenRowTable + $12), column = the margin
;
; Witness: L1 301 (c1, death, m10, m2erbe, m2ocean, menu, missions, play,
; play2, search).
SmallNewLine:
  LD HL,(PrintSmallChar+$0012)
  LD BC,$0012
  ADD HL,BC
  LD (PrintSmallChar+$0012),HL
  LD A,(CodeNewLine+$000B)
  CALL SmallFontColumn
  EXX
  RET

; Control code 9: the next byte is the left margin ($6F58)
;
; Witness: L1 169 (c1, death, m10, m2erbe, m2ocean, menu, missions, play,
; play2, search).
CodeLeftMargin:
  EXX
  LD A,(HL)
  INC HL
  LD (CodeNewLine+$000B),A
  RET

; Control code 12: the margin = the current column
;
; Witness: known only from the code.
CodeMarginHere:
  LD A,(PrintChar+$0008)
  LD (CodeNewLine+$000B),A
  EXX
  RET

; Control code 13: the next byte is the attribute of the characters ($7025)
;
; Witness: L1 1325 (c1, death, m10, m2erbe, m2ocean, menu, missions, play,
; play2, search).
CodeInk:
  EXX
  LD A,(HL)
  INC HL
  LD (l_7018+$000D),A
  RET

; The 18 control code routines of PrintString (codes 0-17)
;
; Read by `PrintString` at `$6FC7`: code n calls the word n. 14 used, 4 zero.
ControlCodes:
  DEFW CodeColumn,CodeAt
  DEFW CodeAtColumn,CodeNumberA
  DEFW CodeHex,CodeSmallChars
  DEFW CodeSmallAt,CodeSmallFont
  DEFW CodeNumber,CodeLeftMargin
  DEFW SmallNewLine,CodeNewLine
  DEFW CodeMarginHere,CodeInk
  DEFW $0000,$0000
  DEFW $0000,$0000

; Print the string at HL: characters, control codes below $20, tokens from $82,
; $FF the end
;
; Witness: L1 2130 (c1, death, m10, m2erbe, m2ocean, menu, missions, play,
; play2, search).
PrintString:
  LD A,(HL)
  INC HL
  CP $FF
  RET Z
  CP $82
  JR NC,l_6FDB
  CP $20
  JR C,l_6FC6
  EXX
  CALL PrintChar
  JR PrintString
l_6FC6:
  EXX
  LD HL,ControlCodes
  ADD A,A
  LD C,A
  LD B,$00
  ADD HL,BC
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD (CallControl+$0001),DE

; CallControl
CallControl:
  CALL CallControl        ; CALL n: n ($6FD7) patched with the control code's
                          ; routine
  JR PrintString
; This entry point is used by the routine at PrintString.
l_6FDB:
  PUSH HL
  LD HL,StepY+$0001
  SUB $82
  ADD A,A
  LD C,A
  LD B,$00
  ADD HL,BC
  LD E,(HL)
  INC HL
  LD D,(HL)
  EX DE,HL
  CALL PrintString
  POP HL
  JR PrintString

; Print the 8x8 character A at the current cell and its attribute ($7025), then
; the next column
;
; In column 31 it writes no attribute and starts a new line (CodeNewLine)
; instead (`$700F`).
;
; Witness: L1 6525 (c1, death, m10, m2erbe, m2ocean, menu, missions, play,
; play2, search).
PrintChar:
  CALL GlyphAddress
  LD B,$08
  EXX
  PUSH HL
  LD BC,$0000
  LD HL,$0000
  EXX
l_6FFE:
  LD A,(HL)
  INC HL
  EXX
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  EX DE,HL
  ADD HL,BC
  LD (HL),A
  EX DE,HL
  EXX
  DJNZ l_6FFE
  LD A,(PrintChar+$0008)
  CP $1F
  JR C,l_7018
  CALL CodeNewLine
  POP HL
  RET
l_7018:
  LD BC,(CodeNewLine+$0010)
  LD H,$00
  LD L,A
  INC A
  LD (PrintChar+$0008),A
  ADD HL,BC
  LD A,$00
  LD (HL),A
  POP HL
  RET

; Control code 6: the small font's line from the next byte
;
; Witness: L1 1122 (c1, death, m10, m2erbe, m2ocean, menu, missions, play,
; play2, search).
CodeSmallAt:
  EXX
  LD A,(HL)
  INC HL
  EX DE,HL
  LD H,$00
  LD L,A
  ADD HL,HL
  LD BC,ScreenRowTable
  ADD HL,BC
  LD (PrintSmallChar+$0012),HL
  LD HL,PrintSmallChar
  LD (PrintString+$000F),HL
  EX DE,HL
  RET

  ORG $7C59

; The small font: 44 glyphs "0" to "[", 5 rows of a byte each, ink 0 (the
; glyphs are stored inverted)
;
; Read by SmallGlyph `$6DDA` (HL = `$7C59` + 5 (code - "0")) for the panel's
; numbers and short words; the 5 pixels a row are the high bits, the low three
; always 1. Witness: every read build (185 of the 220 bytes read; "@", ":", "<"
; ... never).
SmallFont:
  INCBIN "res/fonts/small-font.bin",$0000,220

; 28 bytes after the font that no routine reads or writes (leftover of an
; earlier build)
SmallFontLeftover:
  DEFB $CD,$88,$72,$21,$00,$00,$11,$00,$00,$A7,$ED,$52,$44,$4D,$EB,$11
  DEFB $F3,$DB,$C5,$CD,$78,$72,$C1,$ED,$B0,$C3,$9B,$72
