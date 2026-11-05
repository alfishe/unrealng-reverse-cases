; --------------------------------------------------------------------------------------------------------------------
; text.asm: the text: typed down the screen's right columns, held, wiped
;
; The right side of the screen: the credits typed a character a frame down a column (24 rows), the next line in the
; next column to the left, ten columns; they stay 200 frames, then the ten columns go black from the right a frame
; each, and the next ten lines come. The 100 lines of ScrollerText (src/res/intro/scroller/text.txt) are ten screens:
; a cycle is 10 x (240 + 1 + 200 + 11) frames, about 4520 (work/stage3/NOTES.md: "about 4500"); after the last line
; ("PRESS 'SPACE'", "AND", "N'JOY !!!") the text starts again.
;
; It all runs in the interrupt: ScrollerStart writes CALL TextInterrupt into LoaderHook, so LoaderInterrupt
; (src/loader.asm) calls it every frame after the tune. Three stages, each a CALL NZ whose flag (the LD A before it)
; the stages switch: TypeChar (TypeOn), HoldText (HoldOn), WipeColumn (WipeOn). The glyphs lie turned a quarter
; clockwise in ScrollerFont, so the columns read top down with the head turned right.
; --------------------------------------------------------------------------------------------------------------------

; the text's frame, called from LoaderInterrupt through LoaderHook
;
; JP TextStages; TextStop turns it into JP TextDone (the text off), which
; nothing reaches in this block.
TextInterrupt:
  JP TextStages
TextStages:
  LD A,$00                ; A = the finale flag (0: never set in this block):
                          ; nonzero runs TextFinale instead
  OR A
  JP NZ,TextFinale
TypeOn:
  LD A,$FF                ; A = $FF: typing (operand, switched by TypeChar and
                          ; WipeColumn)
  OR A
  CALL NZ,TypeChar

; HoldOn
HoldOn:
  LD A,$00                ; A = 0: holding (operand, switched by TypeChar and
                          ; HoldText)
  OR A
  CALL NZ,HoldText

; WipeOn
WipeOn:
  LD A,$00                ; A = 0: wiping (operand, switched by HoldText and
                          ; WipeColumn)
  OR A
  CALL NZ,WipeColumn

; TextStagesDone
TextStagesDone:
  JP TextDone             ; this frame's stages done
; This entry point is used by the routine at TextInterrupt.
TextFinale:
  LD A,$0B                ; never run (TextStages' flag is never set): wipe 10
                          ; columns, type 240 characters more, then the text
                          ; off
  DEC A
  JP Z,TextFinaleType
  EX AF,AF'
  CALL WipeColumn
  EX AF,AF'
  LD (TextFinale+$0001),A
TextFinaleType:
  LD A,$F1                ; then 240 characters
  DEC A
  JP Z,TextStop
  EX AF,AF'
  CALL TypeChar
  EX AF,AF'
  LD (TextFinaleType+$0001),A
  JP TextDone
TextStop:
  LD HL,TextDone          ; the text off: TextInterrupt jumps to TextDone
  LD (TextInterrupt+$0001),HL
TextDone:
  RET                     ; nothing more this frame

; never called: page A at $C000 (BANKM kept)
;
; The loader's SetPage, used only by ScrollerUnusedShow.
ScrollerSetPage:
  PUSH BC
  LD BC,$7FFD
  LD ($5B5C),A
  OUT (C),A
  POP BC
  RET

; the credits: 100 lines of 24 characters, one a column
;
; Read by TypeChar a character a frame; codes $20-$5F (ScrollerFont). Built
; from src/res/intro/scroller/text.txt.
ScrollerText:
  INCBIN "res/scroller/text.bin",$0000,2400

; 0: the text's end, TypeChar starts again at ScrollerText
ScrollerTextEnd:
  DEFB $00

; one column of the text black, from the right; after 10 (and a frame), typing
; again
;
; Used by the routines at WipeOn and TextStagesDone.
WipeColumn:
  LD A,$0B                ; A = the frames left (operand, 11 to 0)
  DEC A
  JP NZ,WipeNext
  LD (WipeOn+$0001),A     ; done: WipeOn off ...
  CPL                     ; ... TypeOn on
  LD (TypeOn+$0001),A
  LD A,$0B                ; 11 frames for the next wipe, from column 31
  LD (WipeColumn+$0001),A
  LD A,$1F
  LD (WipeAddress+$0001),A
  RET
WipeNext:
  LD (WipeColumn+$0001),A ; the frames left
WipeAddress:
  LD HL,$581F             ; HL = the column's top attribute (operand: $581F,
                          ; then one left a frame)
  LD A,L
  DEC A
  LD (WipeAddress+$0001),A
  XOR A                   ; 24 attributes down the column to 0 (black on black)
  LD DE,$0020
  LD (HL),A
  ADD HL,DE
  LD (HL),A
  ADD HL,DE
  LD (HL),A
  ADD HL,DE
  LD (HL),A
  ADD HL,DE
  LD (HL),A
  ADD HL,DE
  LD (HL),A
  ADD HL,DE
  LD (HL),A
  ADD HL,DE
  LD (HL),A
  ADD HL,DE
  LD (HL),A
  ADD HL,DE
  LD (HL),A
  ADD HL,DE
  LD (HL),A
  ADD HL,DE
  LD (HL),A
  ADD HL,DE
  LD (HL),A
  ADD HL,DE
  LD (HL),A
  ADD HL,DE
  LD (HL),A
  ADD HL,DE
  LD (HL),A
  ADD HL,DE
  LD (HL),A
  ADD HL,DE
  LD (HL),A
  ADD HL,DE
  LD (HL),A
  ADD HL,DE
  LD (HL),A
  ADD HL,DE
  LD (HL),A
  ADD HL,DE
  LD (HL),A
  ADD HL,DE
  LD (HL),A
  ADD HL,DE
  LD (HL),A
  RET

; the typed screen held 200 frames, then the wipe
;
; Used by the routine at HoldOn.
HoldText:
  LD A,$C8                ; A = the frames left (operand)
  DEC A
  JP NZ,HoldStore
  LD (HoldOn+$0001),A     ; done: HoldOn off ...
  CPL                     ; ... WipeOn on
  LD (WipeOn+$0001),A
  LD A,$C8
HoldStore:
  LD (HoldText+$0001),A   ; the frames left
  LD A,$00                ; A = 0: TextHook (a RET) is called
  OR A
  CALL Z,TextHook
  RET

; one character of the text, a frame; after 240 the hold
;
; Used by the routines at TextInterrupt and TextStagesDone.
TypeChar:
  LD A,$F1                ; A = the frames left in this screen (operand, 241)
  DEC A
  JP NZ,TypeRow
  LD A,$FF                ; done: the next screen starts at column 31 ...
  LD (TextColumn+$0001),A
  LD (HoldOn+$0001),A     ; ... HoldOn on ...
  CPL                     ; ... TypeOn off
  LD (TypeOn+$0001),A
  LD A,$F1
  LD (TypeChar+$0001),A
  RET
TypeRow:
  LD (TypeChar+$0001),A   ; the frames left
RowCount:
  LD A,$01                ; A = the rows left in the column (operand: 1 at the
                          ; start, so the first frame starts a column)
  DEC A
  JP NZ,RowStore
  LD A,(TextColumn+$0001) ; a new column: one left of the last (TextColumn + 1)
  INC A
  LD (TextColumn+$0001),A
  XOR A                   ; from the top row (RowPointer's low byte 0)
  LD (RowPointer+$0001),A
  LD A,$18                ; 24 rows
RowStore:
  LD (RowCount+$0001),A   ; the rows left
RowPointer:
  LD HL,TextRows          ; HL = the row's entry in TextRows (operand)
  LD A,(HL)
  INC L
  LD B,(HL)
  INC L
  LD (RowPointer+$0001),HL
TextColumn:
  SUB $FF                 ; A = the row's address low byte - the column count:
                          ; the column (operand)
  LD C,A
TextPointer:
  LD HL,ScrollerText      ; HL = the next character (operand)
  LD A,(HL)
  OR A                    ; 0: the end of the text ...
  JP NZ,TypeGlyph
  LD HL,ScrollerText      ; ... the first character again
  LD A,(HL)
TypeGlyph:
  INC HL                  ; the next character on
  LD (TextPointer+$0001),HL
  LD L,A                  ; HL = TextRows + code x 8: the glyph (codes $20-$5F:
                          ; ScrollerFont)
  LD H,$00
  LD DE,TextRows
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,DE
  LD A,(HL)               ; 8 lines of the glyph down the character cell
  LD (BC),A
  INC HL
  INC B
  LD A,(HL)
  LD (BC),A
  INC HL
  INC B
  LD A,(HL)
  LD (BC),A
  INC HL
  INC B
  LD A,(HL)
  LD (BC),A
  INC HL
  INC B
  LD A,(HL)
  LD (BC),A
  INC HL
  INC B
  LD A,(HL)
  LD (BC),A
  INC HL
  INC B
  LD A,(HL)
  LD (BC),A
  INC HL
  INC B
  LD A,(HL)
  LD (BC),A
  LD A,B                  ; the cell's attribute address
  RRCA
  RRCA
  RRCA
  AND $03
  OR $58
  LD B,A
  LD A,$47                ; bright white on black
  LD (BC),A
  LD A,$00                ; A = 0: TextHook (a RET) is called
  OR A
  CALL Z,TextHook
  RET

; RET: a hook HoldText and TypeChar call, left empty
;
; Used by the routines at HoldText and TypeChar.
TextHook:
  RET
