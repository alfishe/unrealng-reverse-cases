; --------------------------------------------------------------------------------------------------------------------
; fade.asm: The corner gradients and the exit fade
;
; The four 5x5 corners of the attributes are gradients from CornerColours $ADF4 (src/res/tables/corner-colours.txt):
; the top-left and bottom-right corners a colour a row, the top-right and bottom-left ones a colour a column. At the
; launch ExitFade $6E72 shifts every pixel row out of its bytes in 8 passes, alternately in and out, until the screen
; is black.
; --------------------------------------------------------------------------------------------------------------------

  ORG $6CBF

; Colour the four 5x5 corners with CornerColours
;
; Witness: L1 4 (c1-c4).
ColourCorners:
  LD HL,Attributes
  CALL ColourCornerRows
  LD HL,Attributes+635
  CALL ColourCornerRows
  IFDEF CornersPlain
  LD HL,Attributes+27     ; variant: all four corners through ColourCornerRows
  CALL ColourCornerRows
  LD HL,Attributes+608
  CALL ColourCornerRows
  ELSE
  LD DE,Attributes+27
  CALL ColourCornerColumns
  LD DE,Attributes+608
  CALL ColourCornerColumns
  ENDIF
  RET

; At HL, 5 rows of 5 cells: row n all CornerColours[n]
;
; Witness: L1 8 (c1-c4).
ColourCornerRows:
  LD B,$05
  IFDEF CornersPlain
  LD A,$04                ; variant: one colour, green ink, for every cell
  NOP
  ELSE
  LD DE,CornerColours
  ENDIF
CornerRowsNext:
  LD C,$05
  IFDEF CornersPlain
  NOP
  ELSE
  LD A,(DE)
  ENDIF
CornerRowsCell:
  LD (HL),A
  INC HL
  DEC C
  JR NZ,CornerRowsCell
  INC DE
  PUSH BC
  LD BC,$001B
  ADD HL,BC
  POP BC
  DJNZ CornerRowsNext
  RET

; At DE, 5 rows of 5 cells, each row the 5 CornerColours
;
; Witness: L1 8 (c1-c4).
ColourCornerColumns:
  LD B,$05
CornerColumnsRow:
  PUSH BC
  LD BC,$0005
  LD HL,CornerColours
  LDIR
  EX DE,HL
  LD BC,$001B
  ADD HL,BC
  EX DE,HL
  POP BC
  DJNZ CornerColumnsRow
  RET

  ORG $6E72

; Shift every pixel row out of its bytes in 8 passes: the screen goes black
;
; Witness: L1 2 (c2, c3).
ExitFade:
  LD D,$08
ExitFadePass:
  LD C,$10
  LD HL,Screen
ExitFadeLine:
  LD B,C
ExitFadeIn:
  XOR A
  RR (HL)
  INC HL
  XOR A
  RL (HL)
  INC HL
  DJNZ ExitFadeIn
  LD B,C
ExitFadeOut:
  XOR A
  RL (HL)
  INC HL
  XOR A
  RR (HL)
  INC HL
  DJNZ ExitFadeOut
  LD A,H
  CP $58
  JR NZ,ExitFadeLine
  DEC D
  JR NZ,ExitFadePass
  RET
