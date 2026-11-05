; --------------------------------------------------------------------------------------------------------------------
; print64.asm: the 64-column printer (relocated to $8156)
;
; Characters are 4 pixels wide: a font byte holds two glyphs' rows (high nibble for the even code, low for the odd:
; Font + (code >> 1) * 8, 7 rows from the second byte), and DrawHalfChar merges the glyph's nibble into the screen
; byte at column >> 1, the left or the right half by the column's bit 0. PrintColumn (0-63) and PrintRow (0-23) are
; the position; PrintChar draws and advances, wrapping at 64.
;
; PrintInit opens stream 2 and points channel S's output at ChannelOut, so the ROM's PR_STRING and RST $10 print
; through it: codes from 31 up are glyphs, 12 clears the screen, 13 is a new line, the rest is ignored. A new line or
; a character past row 23 scrolls the screen up a row (ScrollUp).
; --------------------------------------------------------------------------------------------------------------------

; stream 2 opened, the position 0, 0, channel S's output = ChannelOut
PrintInit:
  LD A,$02
  CALL CHAN_OPEN
  LD A,$00
  LD (PrintColumn),A
  LD A,$00
  LD (PrintRow),A
  LD HL,ChannelOut
  LD (ChannelSOutput),HL
  RET

; three zero bytes
Spare:
  DEFB $00,$00,$00

; A drawn at the position, the column advanced (64 = the next row)
;
; Used by the routines at ChannelOut and PrintString64.
PrintChar:
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  CALL DrawHalfChar
  LD HL,PrintColumn
  INC (HL)
  BIT 6,(HL)
  JR Z,l_8182
  LD (HL),$00
  INC HL
  INC (HL)
l_8182:
  POP HL
  POP DE
  POP BC
  POP AF
  RET

; unused, older layout: B rows moved up; its CALL $815F lands inside PrintInit
;
; No call reaches it. Its CALL $815F was a routine of the package's earlier
; layout (the screen address of row L): in this copy $815F is the operand of
; PrintInit's LD ($8461),A, so the routine would not run right. It and
; ScrollRowsDownOld use LineCopy, as ScrollUp does through ScrollRowsDown.
ScrollRowsUpOld:
  LD A,$15
  SUB B
  RET Z
  LD L,$15
  CALL OLD_CODE_815F
  LD E,L
  LD D,H
l_8192:
  PUSH AF
  LD A,L
  SUB $20
  LD L,A
  JR NC,l_819D
  LD A,H
  SUB $08
  LD H,A
l_819D:
  CALL LineCopy
  LD A,E
  SUB $20
  LD E,A
  JR NC,l_81AA
  LD A,D
  SUB $08
  LD D,A
l_81AA:
  POP AF
  DEC A
  JR NZ,l_8192
  RET

; unused, older layout: rows moved down from row B; the same CALL $815F
ScrollRowsDownOld:
  LD A,$15
  SUB B
  RET Z
  LD L,B
  CALL OLD_CODE_815F
  LD E,L
  LD D,H

; A pixel-row groups moved: HL from DE + 32 (the next character row), LineCopy
; each
;
; Entered with A = the rows, HL = DE = the first row's address; ScrollUp calls
; it for 23 rows from Screen. The loop is the second half of
; ScrollRowsDownOld's body.
ScrollRows:
  PUSH AF
  LD A,L
  ADD A,$20
  LD L,A
  JR NC,l_81C4
  LD A,H
  ADD A,$08
  LD H,A
l_81C4:
  CALL LineCopy
  LD A,E
  ADD A,$20
  LD E,A
  JR NC,l_81D1
  LD A,D
  ADD A,$08
  LD D,A
l_81D1:
  POP AF
  DEC A
  JR NZ,ScrollRows
  RET

; one character row (8 pixel lines of 32 bytes) from HL to DE, alternating LDI
; and LDD lines
;
; The first line is copied from the row's second pixel line (INC H / INC D
; first) forwards with 31 LDI and a last byte, the next backwards with LDD, and
; so on: no pointer reload between the lines. The top pixel line of each row is
; not copied (the font leaves it blank).
LineCopy:
  PUSH HL
  PUSH DE
  INC H
  INC D
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LD A,(HL)
  LD (DE),A
  INC D
  INC H
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LD A,(HL)
  LD (DE),A
  INC D
  INC H
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LD A,(HL)
  LD (DE),A
  INC D
  INC H
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LD A,(HL)
  LD (DE),A
  INC D
  INC H
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LD A,(HL)
  LD (DE),A
  INC D
  INC H
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LDD
  LD A,(HL)
  LD (DE),A
  INC D
  INC H
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LD A,(HL)
  LD (DE),A
  POP DE
  POP HL
  RET

; HL down one character row (32 bytes; a new third: +8 to H)
NextRowAddress:
  LD A,L
  ADD A,$20
  LD L,A
  RET NC
  LD A,H
  ADD A,$08
  LD H,A
  RET

; HL up one character row
PreviousRowAddress:
  LD A,L
  SUB $20
  LD L,A
  RET NC
  LD A,H
  SUB $08
  LD H,A
  RET

; HL = the screen address of the position (column >> 1), carry = the column's
; bit 0
;
; Used by the routines at DrawHalfChar, EraseHalfChar and CursorXor.
CellAddress:
  LD A,(PrintColumn)
  SRL A
  LD B,A
  PUSH AF
  LD A,(PrintRow)
  LD C,A
  AND $18
  OR $40
  LD H,A
  LD A,C
  AND $07
  RRCA
  RRCA
  RRCA
  OR B
  LD L,A
  POP AF
  RET

; A's glyph at the position: a space erases the half cell (EraseHalfChar)
;
; The glyph rows come from Font + (A >> 1) * 8 + 1; A's bit 0 says which nibble
; of the font byte, the column's bit 0 which half of the screen byte: four ways
; (the same half: masked; the other: shifted by four RLCAs).
DrawHalfChar:
  CP $20
  JR Z,EraseHalfChar
  SRL A
  PUSH AF
  LD H,$00
  LD L,A
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD DE,Font
  ADD HL,DE
  EX DE,HL
  CALL CellAddress
  INC DE
  INC H
  LD B,$07
  JP C,DrawRightHalf
  POP AF
  JP NC,DrawEvenLeft
l_83F7:
  LD A,(HL)               ; an even column, an odd code: the font's low nibble
                          ; moved to the left (high) half
  AND $0F
  LD C,A
  LD A,(DE)
  RLCA
  RLCA
  RLCA
  RLCA
  AND $F0
  OR C
  LD (HL),A
  INC DE
  INC H
  DJNZ l_83F7
  RET

; the position's half cell cleared (7 pixel lines)
;
; Used by the routine at DrawHalfChar.
EraseHalfChar:
  CALL CellAddress
  INC H
  LD C,$0F
  JP NC,l_8414
  LD C,$F0
l_8414:
  LD A,C
  AND (HL)
  LD (HL),A
  INC H
  LD A,C
  AND (HL)
  LD (HL),A
  INC H
  LD A,C
  AND (HL)
  LD (HL),A
  INC H
  LD A,C
  AND (HL)
  LD (HL),A
  INC H
  LD A,C
  AND (HL)
  LD (HL),A
  INC H
  LD A,C
  AND (HL)
  LD (HL),A
  INC H
  LD A,C
  AND (HL)
  LD (HL),A
  RET
; This entry point is used by the routine at DrawHalfChar.
DrawEvenLeft:
  LD A,(HL)               ; an even column, an even code: the font's high
                          ; nibble into the left half
  AND $0F
  LD C,A
  LD A,(DE)
  AND $F0
  OR C
  LD (HL),A
  INC DE
  INC H
  DJNZ DrawEvenLeft
  RET
; This entry point is used by the routine at DrawHalfChar.
DrawRightHalf:
  POP AF                  ; an odd column: the right (low) half of the screen
                          ; byte
  JR NC,DrawEvenRight
l_8441:
  LD A,(HL)               ; an odd code: the font's low nibble as it is
  AND $F0
  LD C,A
  LD A,(DE)
  AND $0F
  OR C
  LD (HL),A
  INC DE
  INC H
  DJNZ l_8441
  RET
DrawEvenRight:
  LD A,(HL)               ; an even code: the font's high nibble moved to the
                          ; right half
  AND $F0
  LD C,A
  LD A,(DE)
  RLCA
  RLCA
  RLCA
  RLCA
  AND $0F
  OR C
  LD (HL),A
  INC DE
  INC H
  DJNZ DrawEvenRight
  RET

; the print position's column (0-63) ...
PrintColumn:
  DEFB $00

; ... and row (0-23); written as one word too
PrintRow:
  DEFB $00

; unused: wait for a key with a blinking cursor at InputPosition, a click, its
; code in A (the case swapped)
;
; No call in the menu reaches it. It sets PageCounter's count to 23, puts the
; position at InputPosition, XORs the cursor in and out around the key wait
; (FLAGS bit 5), clicks with BEEPER when ClickOn is not 0 (the border
; ClickBorder through BORDCR) and swaps the key's case (SwapCase).
InputLine:
  PUSH HL
  PUSH DE
  PUSH BC
  PUSH IX
  LD A,$17
  LD (PageCounter+$0001),A
  LD IX,InputPosition
  LD A,(IX+$00)
  LD HL,PrintColumn
  LD (HL),A
  LD A,(IX+$01)
  INC HL
  LD (HL),A
  CALL CursorXor
l_8480:
  EI
  BIT 5,(IY+$01)
  JR NZ,l_848A
  HALT
  JR l_8480
l_848A:
  LD A,(IY-$32)
  RES 5,(IY+$01)
  EX AF,AF'
  CALL CursorXor
  LD A,(ClickOn)
  AND A
  JR Z,l_84AA
  LD A,(ClickBorder)
  LD (IY+$0E),A
  LD HL,$001E
  LD DE,$001E
  CALL BEEPER
l_84AA:
  EX AF,AF'
  CALL SwapCase
  POP IX
  POP BC
  POP DE
  POP HL
  RET

; the half cell at the position inverted (8 pixel lines)
;
; Used by the routine at InputLine.
CursorXor:
  CALL CellAddress
  LD A,$F0
  JR NC,l_84BD
  LD A,$0F
l_84BD:
  LD C,A
  LD B,$08
l_84C0:
  LD A,C
  XOR (HL)
  LD (HL),A
  INC H
  DJNZ l_84C0
  RET

; A's letter case swapped (A-Z <-> a-z)
;
; Used by the routine at InputLine.
SwapCase:
  CP $41
  RET C
  CP $5B
  JR NC,l_84D1
  ADD A,$20
  RET
l_84D1:
  CP $61
  RET C
  CP $7B
  JR NC,TranslateKey
  SUB $20
  RET

; A through KeyTable: the second byte of the pair whose first is A (no end
; mark: A must be in the table)
;
; Used by the routine at SwapCase.
TranslateKey:
  LD HL,KeyTable
l_84DE:
  CP (HL)
  JR Z,l_84E5
  INC HL
  INC HL
  JR l_84DE
l_84E5:
  INC HL
  LD A,(HL)
  RET

; (key code, character) pairs: the Symbol Shift codes of the BASIC tokens to ~
; | { } [ ] and \
KeyTable:
  DEFB $E2,$7E
  DEFB $C3,$7C
  DEFB $CC,$7B
  DEFB $CB,$7D
  DEFB $C6,$5B
  DEFB $C5,$5D
  DEFB $C7,$C7
  DEFB $C9,$C9
  DEFB $C8,$C8
  DEFB $CD,$5C
  DEFB $AC,$AC
  DEFB $00,$85

; channel S's output: 31 and up a glyph, 12 clears the screen, 13 a new line;
; row 24 scrolls
ChannelOut:
  PUSH AF
  PUSH IX
  LD IX,InputPosition
  CP $1F
  JR NC,l_8517
  CP $0C
  JP Z,ClearAll
  CP $0D
  JP Z,NewLine
  JR ChannelOutEnd
l_8517:
  CALL PrintChar          ; a glyph
; This entry point is used by the routine at NewLine.
l_851A:
  LD A,(PrintRow)         ; after a glyph or a new line: past row 23?
  CP $18
  JR Z,ScrollUp
; This entry point is used by the routine at ScrollUp.
l_8521:
  NOP                     ; 16 NOPs: room left in the package
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
; This entry point is used by the routine at ClearAll.
ChannelOutEnd:
  POP IX
  POP AF
  RET

; the screen one character row up (ScrollRows from Screen, 23 rows), row 23
; cleared, the row back to 23
;
; Used by the routine at ChannelOut.
ScrollUp:
  PUSH BC
  PUSH DE
  PUSH HL
  LD HL,Screen
  LD D,H
  LD E,L
  LD A,$17
  CALL ScrollRows
  LD HL,ScreenRow23
  XOR A
  LD B,$08
l_8548:
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  LD L,$E0
  INC H
  DJNZ l_8548
  LD A,$17
  LD (PrintRow),A
  POP HL
  POP DE
  POP BC
  JR l_8521

; code 12: bitmap cleared, attributes = ATTR_P, the position 0, 0
;
; Used by the routine at ChannelOut.
ClearAll:
  PUSH HL
  PUSH DE
  PUSH BC
  PUSH AF
  LD HL,Screen
  LD DE,Screen+1
  LD BC,$1AFF
  XOR A
  LD (HL),A
  LDIR
  LD A,(ATTR_P)
  LD HL,Attrs
  LD DE,Attrs+1
  LD BC,$02FF
  LD (HL),A
  LDIR
  LD HL,$0000
  LD (PrintColumn),HL
  POP AF
  POP BC
  POP DE
  POP HL
  JP ChannelOutEnd

; unused code of the package's earlier layout: no set-up before it, a CALL into
; the font
;
; Read as instructions: 20 x PUSH HL and DJNZ (a clear by PUSH without its LD
; SP before it), LD SP,$74EB, the border black, RepeatPeriod / RepeatDelay to
; REPPER / REPDEL, PageCounter's count 23, the position 0, CALL $88C4 (the font
; here: OLD_CODE_88C4), POP HL, POP BC, JP $851A. No jump reaches it.
LeftoverCode:
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$10,$E6,$31,$EB,$74
  DEFB $3E,$00,$D3,$FE,$3A,$33,$86,$FD
  DEFB $77,$D0,$3A,$34,$86,$FD,$77,$CF
  DEFB $3E,$17,$32,$0A,$86,$21,$00,$00
  DEFB $22,$61,$84,$CD,$C4,$88,$E1,$C1
  DEFB $C3,$1A,$85

; code 13: column 0, the next row
;
; Used by the routine at ChannelOut.
NewLine:
  XOR A
  LD (PrintColumn),A
  LD HL,PrintRow
  INC (HL)
  JP l_851A

; unused: counts lines down from the count in the operand (PageCount); at 0
; wait for a key (InputLine)
PageCounter:
  LD A,$16
  DEC A
  LD (PageCounter+$0001),A
  RET NZ
  JP InputLine

; unused: the zero-ended string after the CALL printed with RST $10, the return
; after it
PrintInline:
  EX (SP),HL
  PUSH AF
  CALL PrintStringRst
  POP AF
  EX (SP),HL
  RET

; unused: the zero-ended string at HL with RST $10
;
; Used by the routine at PrintInline.
PrintStringRst:
  LD A,(HL)
  OR A
  RET Z
  RST $10
  INC HL
  JR PrintStringRst

; unused: the zero-ended string at HL with PrintChar
PrintString64:
  LD A,(HL)
  OR A
  RET Z
  CALL PrintChar
  INC HL
  JR PrintString64

; unused: a BASIC error report A (LD SP,(ERR_SP), the code into ERR_NR)
ErrorReturn:
  LD SP,(ERR_SP)
  LD (IY+$00),A
  RET

; the keyboard repeat period the leftover code sets (2)
RepeatPeriod:
  DEFB $02

; the keyboard repeat delay the leftover code sets (14)
RepeatDelay:
  DEFB $0E

; the border colour during the click
ClickBorder:
  DEFB $07

; 0 = no click
ClickOn:
  DEFB $01

; 128 x 8 bytes: two 4-pixel glyphs a byte (codes 0-255), the first byte of
; each eight unused
Font:
  INCBIN "../../res/trd/boot/font64.bin",$0000,1023
