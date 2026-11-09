; --------------------------------------------------------------------------------------------------------------------
; printing.asm: The pocket multiplier marks, the number printer, the text printer and its glyph lookup
;
; PrintChar $9E7C prints character A at row H, column L with attribute C. C bit 7 = double width: the attribute (C AND
; $7F) goes into two cells and the glyph is widened (PrintCharWide); the string and number printers then step two
; columns. Glyphs: $61-$7A (a-z) Font $DEF4, $30-$39 (0-9) Font+208, $7F the copyright sign CopyrightGlyph $9F2E,
; every other code CHAR_SET + 8 (code - $20) (upper case, space, punctuation from the ROM).
; --------------------------------------------------------------------------------------------------------------------

; Print "xN" at the six pockets, clockwise from the top left, N = 1-6 turned by
; PocketTurn $9F43
;
; Cells: top row 5 (y 40) cols 0, 15, 30 then bottom row 23 (y 184) cols 30,
; 15, 0, each a ROM "x" and a digit. The k-th mark (k = 0..5) shows
; ((PocketTurn + k) mod 6) + 1; PocketTurn ends where it started (six
; increments). The scoring and the own-pocket rule use PocketTurn + the pocket
; number the same way ($9923, $8C37), so pocket 1 is the top left mark (known
; only from the code). game 4 (frame 6190 on), w1 7, v1 5.
DrawPocketMarks:
  LD HL,Screen+160
  CALL PrintPocketMark
  LD HL,Screen+175
  CALL PrintPocketMark
  LD HL,Screen+190
  CALL PrintPocketMark
  LD HL,Screen+4350
  CALL PrintPocketMark
  LD HL,Screen+4335
  CALL PrintPocketMark
  LD HL,Screen+4320

; At screen address HL: the ROM's "x" glyph, then the digit PocketTurn + 1;
; PocketTurn + 1 mod 6
;
; Used by the routine at DrawPocketMarks.
PrintPocketMark:
  LD DE,CHAR_SET+$02C0    ; CHAR_SET+704: the ROM's "x"
  PUSH HL
  CALL CopyGlyph
  POP HL
  INC L
  LD A,(PlayerVars)
  INC A
  ADD A,A
  ADD A,A
  ADD A,A
  LD DE,FontDigits
  ADD A,E
  LD E,A
  JR NC,PocketMarkDigit
  INC D
PocketMarkDigit:
  CALL CopyGlyph
  LD A,(PlayerVars)
  INC A
  CP $06
  JR C,PocketMarkStore
  XOR A
PocketMarkStore:
  LD (PlayerVars),A
  RET

; Copy 8 bytes from DE down the cell at HL; in the bottom two thirds one byte
; earlier (the glyph one pixel lower)
;
; Used by the routine at PrintPocketMark.
CopyGlyph:
  LD A,H
  CP $48
  JR C,CopyGlyphStart
  DEC DE
CopyGlyphStart:
  LD B,$08
CopyGlyphLoop:
  LD A,(DE)
  LD (HL),A
  INC DE
  INC H
  DJNZ CopyGlyphLoop
  RET

; Print HUD number A: 0 score 1, 1 score 2, 2 hi score (five digits and a "0"),
; 3 shots left, 4 frame (and a space)
;
; Positions (row, column): score 1 (0, 3), score 2 (0, 26), hi (0, 14), shots
; (1, 31), frame (1, 22); attr $3A. The scores print with leading zeros (B =
; $80), shots and frame without. game 15, w1 322, v1 92.
PrintHudNumber:
  LD B,$80
  LD C,$3A
  OR A
  JR NZ,HudNumberScore2
  LD HL,(ScorePlayer1)
  LD DE,$0003
  CALL PrintNumber
  JR HudNumberTimesTen
HudNumberScore2:
  DEC A
  JR NZ,HudNumberHi
  LD HL,(ScorePlayer2)
  LD DE,$001A
  CALL PrintNumber
  JR HudNumberTimesTen
HudNumberHi:
  DEC A
  JR NZ,HudNumberSmall
  LD HL,(HiScore)
  LD DE,$000E
  CALL PrintNumber
HudNumberTimesTen:
  EX DE,HL                ; the fixed "0" after a score
  LD A,$30
  JP PrintChar
HudNumberSmall:
  LD B,$00
  LD HL,(ShotsLeft)
  LD H,$00
  LD DE,$011F
  DEC A
  JR Z,PrintNumber
  LD HL,(FrameNumber)
  LD H,$00
  LD DE,$0116
  CALL PrintNumber
  EX DE,HL
  LD A,$20
  JP PrintChar

; Print HL (0-65535) in decimal at row D, column E, attr C; B bit 7 = keep
; leading zeros. DE out: past the number
;
; Five digits by subtraction (10000, 1000, 100, 10, 1, PrintDigit $9E40);
; without B bit 7 the zeros before the first other digit are skipped and 0
; prints as "0". Callers: the HUD, the tally, the FRAME banner, the hall of
; fame $AA23. game 16, w1 420.
PrintNumber:
  PUSH DE
  BIT 7,B
  JR NZ,PrintNumberDigits
  LD A,H
  OR L
  JR NZ,PrintNumberDigits
  SET 7,B
  JR PrintNumberUnits
PrintNumberDigits:
  LD DE,$2710
  CALL PrintDigit
  LD DE,$03E8
  CALL PrintDigit
  LD DE,$0064
  CALL PrintDigit
  LD DE,$000A
  CALL PrintDigit
PrintNumberUnits:
  LD DE,$0001
  CALL PrintDigit
  POP DE
  RET

; One digit: A = HL / DE (repeated subtraction), print it at the position kept
; on the stack, step the column
;
; Swaps its return address and the position kept on the stack by the caller (EX
; (SP),HL) so the five calls share the position.
PrintDigit:
  XOR A
PrintDigitCount:
  OR A
  SBC HL,DE
  JR C,PrintDigitShow
  INC A
  JR PrintDigitCount
PrintDigitShow:
  ADD HL,DE
  EX DE,HL
  POP HL
  EX (SP),HL
  OR A
  JR NZ,PrintDigitPrint
  BIT 7,B
  JR Z,PrintDigitDone
PrintDigitPrint:
  SET 7,B
  ADD A,$30
  CALL PrintChar
  INC L
  BIT 7,C
  JR Z,PrintDigitDone
  INC L
PrintDigitDone:
  EX (SP),HL
  EX DE,HL
  PUSH DE
  RET

; Print the text record at HL: row, column, attribute (bit 7 double width),
; length N, then N characters
;
; No end marker: the length byte counts. Out: HL = row (H), column (L) after
; the text (callers print a number there); DE past the record. game 138 calls,
; w1 449; callers in the HUD, the tally, the hall of fame ($AA4B, $ACEF), the
; menu ($B22E, $B3F3, $B605, $B67E), the presents page $B8C5 and the editor
; ($C042, $C414).
PrintText:
  LD D,(HL)
  INC HL
  LD E,(HL)
  INC HL
  LD C,(HL)
  INC HL
  LD B,(HL)
  INC HL
  EX DE,HL
PrintTextLoop:
  LD A,(DE)
  CALL PrintChar
  INC L
  BIT 7,C
  JR Z,PrintTextNext
  INC L
PrintTextNext:
  INC DE
  DJNZ PrintTextLoop
  RET

; Print character A at row H (0-23), column L (0-31), attribute C (bit 7:
; double width); keeps all registers
;
; Writes the attribute first (one or two cells), then the glyph (see the module
; text). game 1094 calls, w1 4388, m1 2143.
PrintChar:
  PUSH HL
  PUSH BC
  PUSH DE
  PUSH AF
  CALL CellAddress
  POP AF
  PUSH HL
  CALL CellAttr
  LD B,C
  RES 7,B
  LD (HL),B
  BIT 7,C
  JR Z,PrintCharCopyright
  INC HL
  LD (HL),B
PrintCharCopyright:
  CP $7F
  JR NZ,PrintCharDigit
  SUB $7F
  LD DE,CopyrightGlyph
  JR PrintCharGlyph
PrintCharDigit:
  CP $30
  JR C,PrintCharLower
  CP $3A
  JR NC,PrintCharLower
  SUB $30
  LD DE,FontDigits
  JR PrintCharGlyph
PrintCharLower:
  CP $61
  JR C,PrintCharRom
  CP $7B
  JR NC,PrintCharRom
  SUB $61
  LD DE,Font
  JR PrintCharGlyph
PrintCharRom:
  SUB $20                 ; any other code: CHAR_SET + 8 (A - $20)
  LD DE,CHAR_SET
PrintCharGlyph:
  ADD A,A
  LD H,$00
  LD L,A
  ADD HL,HL
  ADD HL,HL
  ADD HL,DE
  EX DE,HL
  POP HL
  BIT 7,C
  JR Z,PrintCharNarrow
  CALL PrintCharWide
  JR PrintCharDone
PrintCharNarrow:
  LD B,$08
PrintCharNarrowLoop:
  LD A,(DE)
  LD (HL),A
  INC H
  INC DE
  DJNZ PrintCharNarrowLoop
PrintCharDone:
  POP DE
  POP BC
  POP HL
  RET

; Copy glyph DE to cells HL and HL+1 with every pixel doubled across (16 pixels
; a line)
;
; Each glyph byte's low four bits go, doubled, to the right byte, the high four
; to the left. game 56, w1 285.
PrintCharWide:
  LD B,$08
PrintCharWideLoop:
  PUSH BC
  LD A,(DE)
  RRCA
  RR C
  SRA C
  RRCA
  RR C
  SRA C
  RRCA
  RR C
  SRA C
  RRCA
  RR C
  SRA C
  RRCA
  RR B
  SRA B
  RRCA
  RR B
  SRA B
  RRCA
  RR B
  SRA B
  RRCA
  RR B
  SRA B
  LD (HL),B
  INC HL
  LD (HL),C
  DEC HL
  INC H
  INC DE
  POP BC
  DJNZ PrintCharWideLoop
  RET

; HL = the display address of row H (0-23), column L (0-31), line 0
;
; Used by the routines at ShowFrameBanner and PrintChar.
CellAddress:
  LD A,H
  AND $07
  RRCA
  RRCA
  RRCA
  ADD A,L
  LD L,A
  LD A,H
  AND $F8
  OR $40
  LD H,A
  RET

; HL = the attribute address of the display cell address HL
;
; Used by the routine at PrintChar.
CellAttr:
  SRL H
  SRL H
  SRL H
  SET 6,H
  SET 4,H
  RET

; The glyph of character $7F, the copyright sign (a C in a ring)
;
; Read by PrintChar's $7F branch ($9E96: game 2, m1 4; the menu's copyright
; line).
CopyrightGlyph:
  DEFB $7E,$81,$BD,$A1,$A1,$BD,$81,$7E
