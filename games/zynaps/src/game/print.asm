; --------------------------------------------------------------------------------------------------------------------
; print.asm: Print codes, strings, messages and numbers
;
; One print routine draws every text of the game: PrintChar takes a byte, PrintString a string of them, PrintMessage
; the n-th string of the message list. The print position $80AA is an attribute address ($5800-$5AFF): the character
; cell and its attribute at once; the attribute byte $80AC colours every character printed.
;
; Bytes $20-$7F print the ROM font ($3C00 + 8 code) in a "split bold" style: the glyph's rows 1-7 with each row's left
; nibble made bold (OR with the row shifted left, mask $F0), a blank pixel line after the first row. Bytes $80-$FF
; print the game's own 8x8 glyphs (code $80 at $B54F) as they are. Bytes $00-$06 are codes that take the next byte as
; their operand: 0 attribute, 1 ink, 2 paper, 3 column, 4 row, 5 column + n, 6 row + n. In a string $FF ends it and
; $1B n prints message n there (strings nest).
;
; PrintBcd prints 4 BCD bytes (8 digits) with the leading zeros as a fill character.
; --------------------------------------------------------------------------------------------------------------------

; Print a character or take a print code
;
; A: a byte. When a code is pending ($80AD below $20) A is its operand and the
; code's routine from PrintControlTable runs (codes 7-$1F do nothing), then the
; pending mark goes back to $20.
;
; Otherwise a byte below $20 becomes the pending code; a byte from $20 is
; printed at the print position $80AA with the attribute $80AC, the position
; moves one cell right. All registers are kept.
;
; Callers: PrintString, PrintBcd, PrintKeyName, HighScoreEntry.
PrintChar:
  PUSH AF

; PrintCharSave
PrintCharSave:
  PUSH HL
  PUSH DE
  PUSH BC
  LD C,A
  LD A,(PrintPending)     ; a code waiting for its operand?
  CP $20
  JR C,PrintCode
  LD A,C

; PrintCharTest
PrintCharTest:
  CP $20                  ; a code: store it as pending

; PrintCharKind
PrintCharKind:
  JR C,PrintCharDone
  RLCA                    ; DE = 8 A (the glyph offset)
  RLCA
  RLCA
  LD E,A
  AND $07
  LD D,A
  XOR E
  LD E,A
  LD HL,(PrintPos)        ; the attribute first, the position one cell on
  LD A,(PrintAttr)
  LD (HL),A
  INC HL
  LD (PrintPos),HL
  DEC HL
  LD A,H                  ; the screen address of the attribute cell: $58-$5A
                          ; -> $40, $48, $50
  RLCA
  RLCA
  RLCA
  XOR $82

; PrintCharGlyph
PrintCharGlyph:
  LD H,A
  EX DE,HL
  LD A,C                  ; $80-$FF: the game's glyphs
  AND A
  JP M,PrintGlyph
  LD BC,$3C00             ; the ROM font

; PrintRomGlyph
PrintRomGlyph:
  ADD HL,BC               ; HL = the ROM glyph
  LD BC,$06F0             ; B 6 rows, C the bold mask of the left nibble
  INC L                   ; row 0 of the ROM glyph skipped: it is always blank
  LD A,(HL)
  ADD A,A
  AND C
  OR (HL)
  LD (DE),A
  INC D
  XOR A                   ; the blank second pixel line
  LD (DE),A
  INC D

; PrintCharRow
;
; Used by the routine at PrintCharBold.
PrintCharRow:
  INC L                   ; rows 2-7, bold

; PrintCharBold
PrintCharBold:
  LD A,(HL)
  ADD A,A
  AND C
  OR (HL)
  LD (DE),A
  INC D
  DJNZ PrintCharRow

; PrintCharDone
;
; Used by the routine at PrintCharKind.
PrintCharDone:
  POP BC                  ; the byte becomes the pending mark: $20 or more for
                          ; a character, the code itself
  POP DE
  POP HL
  POP AF
  LD (PrintPending),A
  RET
; This entry point is used by the routine at PrintCharGlyph.
PrintGlyph:
  LD BC,Glyphs-$0400      ; the game's glyph $80-$FF: code $80 at $B54F, 8 rows
                          ; as they are
  ADD HL,BC
  LD B,$08
PrintGlyphRow:
  LD A,(HL)
  INC HL
  LD (DE),A
  INC D
  DJNZ PrintGlyphRow
  JR PrintCharDone
; This entry point is used by the routine at PrintCharSave.
PrintCode:
  CP $07                  ; a code with its operand in C
  JR NC,PrintCodeDone     ; 7 and up: no routine
  ADD A,A
  LD E,A
  LD D,$00
  LD HL,PrintControlTable
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD HL,PrintCodeDone     ; the routine returns to PrintCodeDone
  PUSH HL
  EX DE,HL
  JP (HL)

; End a print code: nothing pending
;
; The return of every print code routine (pushed by PrintChar): $80AD = $20,
; the registers PrintChar saved restored.
PrintCodeDone:
  LD A,$20
  LD (PrintPending),A
  POP BC
  POP DE
  POP HL
  POP AF
  RET

; The routines of the print codes 0-6
;
; Each takes its operand in C: PrintSetAttr, PrintSetInk, PrintSetPaper,
; PrintSetColumn, PrintSetRow, PrintColumnRight, PrintRowDown.
PrintControlTable:
  DEFW PrintSetAttr,PrintSetInk,PrintSetPaper,PrintSetColumn,PrintSetRow,PrintColumnRight,PrintRowDown

; Print code 0: the attribute
;
; C: the attribute byte for the next characters ($80AC).
PrintSetAttr:
  LD HL,PrintAttr
  LD (HL),C
  RET

; Print code 1: the ink
;
; C: the ink 0-7 into the attribute $80AC.
PrintSetInk:
  LD HL,PrintAttr
  LD A,(HL)
  AND $F8
  OR C
  LD (HL),A
  RET

; Print code 2: the paper
;
; C: the paper 0-7 into bits 3-5 of the attribute $80AC.
PrintSetPaper:
  LD HL,PrintAttr
  LD A,C
  ADD A,A
  ADD A,A
  ADD A,A
  LD C,A
  LD A,(HL)
  AND $C7
  OR C
  LD (HL),A
  RET

; Print code 3: the column
;
; C: the column 0-31 of the print position.
PrintSetColumn:
  LD HL,PrintPos
  LD A,(HL)
  AND $E0
  OR C
  LD (HL),A
  RET

; Print code 4: the row
;
; C: the row 0-23: the print position's high byte $58 + C / 8, bits 5-7 of the
; low byte C AND 7; the column is kept. Also the end of PrintRowDown.
PrintSetRow:
  LD HL,(PrintPos)
  LD A,C
  RRCA
  RRCA
  RRCA
  LD C,A
  AND $03
  OR $58
  LD H,A
  LD A,C
  XOR L
  AND $E0
  XOR L
  LD L,A
  LD (PrintPos),HL
  RET

; Print code 5: move the column
;
; C: the columns to add (a negative operand, $FE, moves left).
PrintColumnRight:
  LD HL,PrintPos
  LD A,(HL)
  ADD A,C
  LD (HL),A
  RET

; Print code 6: move the row
;
; C: the rows to add to the current row (the position's row from bits 5-9 of
; its offset).
PrintRowDown:
  LD HL,(PrintPos)
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD A,H
  AND $1F
  ADD A,C
  LD C,A
  JR PrintSetRow

; Print a string
;
; HL: the string. Bytes go to PrintChar; $FF ends the string, $1B n prints
; message n (PrintMessage) and goes on. The byte after a print code is its
; operand, never taken as $FF or $1B. HL is kept.
;
; Callers: PrintMessage and the title loop (HiScorePage).
PrintString:
  PUSH AF
  PUSH HL
PrintStringNext:
  LD A,(PrintPending)
  CP $20
  LD A,(HL)
  INC HL
  JR C,PrintStringChar    ; an operand: print it as it is
  CP $FF
  JR Z,PrintStringEnd
  CP $1B
  JR Z,PrintStringMessage
PrintStringChar:
  CALL PrintChar
  JR PrintStringNext
PrintStringMessage:
  LD A,(HL)               ; $1B n: message n
  INC HL
  CALL PrintMessage
  JR PrintStringNext
PrintStringEnd:
  POP HL
  POP AF
  RET

; Print message A
;
; A: the message number. The messages are the $FF-terminated strings from $82EE
; (after the $FF at $82ED); message n starts after the n+1-th $FF from $82ED.
; Registers kept.
;
; Callers: PrintString, the menu screens (RedefineKeys, PrintKeyName,
; SelectPlayers, HighScoreEntry) and LevelStart, CreditsPage, HiScorePage. The
; list of the messages: work/stage1/texts.txt.
PrintMessage:
  PUSH AF
  PUSH HL
  PUSH DE
  PUSH BC
  LD HL,MessageListBase
  LD E,A
  INC E
  LD A,$FF
  LD B,A
PrintMessageFind:
  CPIR                    ; skip to the next $FF
  DEC E
  JR NZ,PrintMessageFind
  CALL PrintString
  POP BC
  POP DE
  POP HL
  POP AF
  RET

; Print a BCD number with spaces for its leading zeros (no caller)
;
; LD C,$20 before PrintBcd: an entry no code calls (the callers load C
; themselves).
PrintBcdSpaces:
  LD C,$20

; Print an 8-digit BCD number
;
; HL: 4 BCD bytes (the high digits first); C: the character printed for each
; leading zero; A': the attribute of the digits after the leading zeros (the
; zeros print with the attribute in $80AC). The number is copied to the scratch
; $7FFC and its digits are taken out a nibble at a time by RLD (the $0F put in
; by the first RLD marks a byte used up). Up to 7 leading zeros are replaced,
; the last digit always prints.
;
; Returns HL past the number. Callers: PrintPlayerScore and the title loop
; (CreditsPage, HiScorePage).
PrintBcd:
  PUSH BC
  LD DE,BcdScratch
  LD BC,$0004
  LDIR
  POP BC
  PUSH HL
  LD HL,BcdScratch
  LD D,$30                ; '0'
  LD B,$07                ; at most 7 leading zeros
  LD A,$0F

; PrintBcdLeading
;
; Used by the routine at PrintBcdLeadNext.
PrintBcdLeading:
  RLD
  CP $0F                  ; $0F back: the byte is used up, the next one
  JR NZ,PrintBcdDigit
  INC HL
  RLD
PrintBcdDigit:
  LD E,A
  AND A
  JR Z,PrintBcdZero
  INC B                   ; the first digit that is not zero: the digits'
                          ; attribute
  EX AF,AF'
  LD (PrintAttr),A
  EX AF,AF'
  JR PrintBcdOut
PrintBcdZero:
  LD A,C                  ; a leading zero: the fill character
  CALL PrintChar

; PrintBcdLeadNext
PrintBcdLeadNext:
  LD A,E
  DJNZ PrintBcdLeading
  INC B                   ; the last digit always prints
  EX AF,AF'
  LD (PrintAttr),A
  EX AF,AF'

; PrintBcdRest
;
; Used by the routine at PrintBcdRestNext.
PrintBcdRest:
  RLD
  CP $0F
  JR NZ,PrintBcdRestDigit
  INC HL
  RLD
PrintBcdRestDigit:
  LD E,A

; PrintBcdOut
;
; Used by the routine at PrintBcdLeading.
PrintBcdOut:
  ADD A,D                 ; '0' + digit
  CALL PrintChar

; PrintBcdRestNext
PrintBcdRestNext:
  LD A,E
  DJNZ PrintBcdRest
  RLD
  POP HL
  RET
