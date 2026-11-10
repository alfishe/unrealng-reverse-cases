; --------------------------------------------------------------------------------------------------------------------
; tapeloader.asm: The loader: the loading picture, tape blocks 3 and 4, the jump to the game
;
; Entered by line 10's USR 24307 (c1 frame 246). It draws the picture from PictureText, paints its colours, loads the
; two headerless blocks with the ROM's LD-BYTES and jumps to the game at $A410 (c1 frame 5292).
; --------------------------------------------------------------------------------------------------------------------

; Draw the loading picture, load blocks 3 and 4, enter the game
;
; Entered once by BASIC line 10 (USR 24307, c1 frame 246). Sets BORDCR to 7
; (white ink for the lower screen), clears the 6912 bytes of the screen from
; AttributesEnd down (c1: 6912 passes of LoaderClear) and makes the border
; black. Then PrintPictureChar draws PictureText: 24 rows of 32 codes from the
; top row (H = 23) down, so the picture fills the screen (c1: 768 characters).
;
; FillAttributes then paints the colours row by row: rows 0-1 white with a cyan
; middle (columns 8-23), rows 2-4 yellow, row 5 white, row 6 white with "IS
; LOADING" flashing cyan (columns 11-20), then three panels: rows 7-13 (the
; keys text, white on red, framed by a red-paper top row and a red-ink bottom
; row), rows 14-18 cyan, rows 19-23 (the fixed keys, framed the same way).
; Columns 0 and 31 of the panels stay black on black (attribute 0 from the
; clear).
;
; Then two calls of the ROM's LD-BYTES with flag $FF: 2 bytes at ERR_SP (tape
; block 3, `01 00`), and 18 900 ($49D4) bytes at GameBlock $8214 (tape block 4,
; the game). The load results are not checked: a failed load runs on. STKBOT
; and STKEND both become $5DC0 (an empty calculator stack inside
; PictureGraphics) and the loader jumps to the game at GameStart $A410 (c1
; frame 5292, T 39 044).
;
; Outputs: the loading screen; ERR_SP = 1, which the game's main loop requires
; (MainLoop $9858); the game image. It never returns.
Loader:
  LD A,$07
  LD (BORDCR),A
  LD HL,AttributesEnd
  LD BC,$1B00
LoaderClear:
  LD (HL),$00             ; 6912 bytes of zeros, from the last attribute down
                          ; to $4000
  DEC HL
  DEC BC
  LD A,B
  OR C
  JR NZ,LoaderClear
  XOR A
  OUT ($FE),A
  LD H,$17
  LD C,$18
  LD DE,PictureText
LoaderRow:
  LD B,$20                ; one row of 32 picture codes (H = the row from the
                          ; bottom, 23 first)
  LD L,$00
LoaderColumn:
  LD A,(DE)
  INC DE
  CALL PrintPictureChar
  INC L
  DJNZ LoaderColumn
  DEC H
  DEC C
  JR NZ,LoaderRow
  LD HL,Attributes             ; the attribute bands, from $5800 on
  LD C,$02
LoaderBand:
  LD A,$07                ; rows 0 and 1: white, cyan in columns 8-23, white
  LD B,$08
  CALL FillAttributes
  LD A,$05
  LD B,$10
  CALL FillAttributes
  LD A,$07
  LD B,$08
  CALL FillAttributes
  DEC C
  JR NZ,LoaderBand
  LD A,$06                ; rows 2-4 yellow, row 5 and row 6 to column 10
                          ; white, "IS LOADING" flashing cyan, white
  LD B,$60
  CALL FillAttributes
  LD A,$07
  LD B,$2B
  CALL FillAttributes
  LD A,$85
  LD B,$0A
  CALL FillAttributes
  LD A,$07
  LD B,$0C
  CALL FillAttributes
  LD A,$10                ; row 7 columns 1-30: red paper, black ink (the
                          ; panel's top)
  LD B,$1E
  CALL FillAttributes
  INC HL
  LD A,$17
  LD C,$05
LoaderPanel:
  LD B,$1E                ; rows 8-12 columns 1-30: red paper, white ink
  INC HL
  CALL FillAttributes
  INC HL
  DEC C
  JR NZ,LoaderPanel
  LD A,$02                ; row 13 red ink, rows 14-18 cyan, row 19 red paper
  LD B,$1E
  INC HL
  CALL FillAttributes
  INC HL
  LD A,$05
  LD B,$A0
  CALL FillAttributes
  INC HL
  LD A,$10
  LD B,$1E
  CALL FillAttributes
  LD C,$03
LoaderPanel2:
  INC HL                  ; rows 20-22 columns 1-30: red paper, white ink; then
                          ; row 23 red ink
  INC HL
  LD A,$17
  LD B,$1E
  CALL FillAttributes
  DEC C
  JR NZ,LoaderPanel2
  INC HL
  INC HL
  LD A,$02
  LD B,$1E
  CALL FillAttributes
  LD IX,ERR_SP             ; tape block 3: two bytes into ERR_SP
  LD DE,$0002
  SCF
  LD A,$FF
  CALL LD_BYTES
  LD IX,GameBlock             ; tape block 4: the game, 18 900 bytes at $8214 (c1
                          ; frame 361 onwards)
  LD DE,GameLength
  SCF
  LD A,$FF
  CALL LD_BYTES
  LD HL,PictureGraphics+$00DD ; an empty calculator stack at $5DC0, inside
                              ; PictureGraphics
  LD (STKBOT),HL
  LD (STKEND),HL
  JP GameStart                ; enter the game

; Fill B bytes from HL with A
;
; Inputs: HL the first byte, B the count, A the value. Output: HL past the last
; byte. Called 16 times by Loader for the attribute bands (c1: 745 bytes).
FillAttributes:
  LD (HL),A
  INC HL
  DJNZ FillAttributes
  RET

; Draw character A at row H (from the bottom), column L
;
; Inputs: A the code, H the character row counted from the bottom of the screen
; (0-23), L the column. The screen address is the third (H 16-23 the top one)
; and the row in it ((H AND 7) XOR 7); the glyph is the ROM font's (RomFont + 8
; x A) for codes below $5F, PictureGraphics + 8 x (A - $60) for $5F and up.
; Eight bytes are copied down the character cell, top row first. Registers
; kept. c1: 768 calls (one picture), 200 of them for codes $60 and up.
PrintPictureChar:
  PUSH HL
  PUSH BC
  PUSH DE
  PUSH AF
  EX DE,HL
  LD A,D
  LD HL,Screen
  LD BC,$0800
  CP $10
  JR NC,l_5FDF
  CP $08
  JR NC,l_5FDE
  ADD HL,BC
l_5FDE:
  ADD HL,BC
l_5FDF:
  AND $07                 ; the row inside the third
  XOR $07
  SLA A
  SLA A
  SLA A
  SLA A
  SLA A
  LD C,A
  LD B,$00
  ADD HL,BC
  LD C,E
  ADD HL,BC
  POP AF
  PUSH AF
  LD DE,RomFont
  CP $5F
  JR C,PrintPictureGlyph
  LD DE,PictureGraphics   ; a picture graphic
  SUB $60
PrintPictureGlyph:
  LD C,A                  ; HL = the glyph, DE = the cell
  XOR A
  SLA C
  RLA
  SLA C
  RLA
  SLA C
  RLA
  LD B,A
  EX DE,HL
  ADD HL,BC
  LD B,$08
PrintPictureLine:
  LD A,(HL)
  LD (DE),A
  INC HL
  INC D
  DJNZ PrintPictureLine
  POP AF
  POP DE
  POP BC
  POP HL
  RET
