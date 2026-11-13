; --------------------------------------------------------------------------------------------------------------------
; render.asm: The renderer: the sprite row plotters, the play buffer, the attributes, ClearBuffer and CopyBuffer
; --------------------------------------------------------------------------------------------------------------------

  ORG $793D

; Fade every coloured ink up to white over 7 frames, then down to black over 7
; frames
;
; Seven times (HALT each): every attribute whose ink is neither 0 nor 7 gets
; ink + 1. Then seven times (two HALTs each): every ink not 0 gets ink - 1.
; Inputs: none; changes the whole attribute area $5800-$5AFF. Called by
; EndStage.
;
; Stage 1's FlashFadeScreen at $7925 is the same code.
;
; Witness: L1 2 (rzx-r3, s3-right).
FlashFadeScreen:
  LD B,$07
FadeUpFrame:
  PUSH BC
  HALT
  LD HL,Attributes
  LD BC,$0300
FadeUpCell:
  LD A,(HL)
  AND $07
  JR Z,FadeUpNext
  CP $07
  JR Z,FadeUpNext
  INC (HL)
FadeUpNext:
  INC HL
  DEC BC
  LD A,B
  OR C
  JR NZ,FadeUpCell
  POP BC
  DJNZ FadeUpFrame
  LD B,$07
FadeDownFrame:
  PUSH BC
  HALT
  HALT
  LD HL,Attributes
  LD BC,$0300
FadeDownCell:
  LD A,(HL)
  AND $07
  JR Z,FadeDownNext
  DEC (HL)
FadeDownNext:
  INC HL
  DEC BC
  LD A,B
  OR C
  JR NZ,FadeDownCell
  POP BC
  DJNZ FadeDownFrame
  RET

  ORG $79BA

; Copy a block of bytes to the screen, line by line
;
; Inputs: HL = the source, B = the screen column, C = the first pixel line, D =
; the width in bytes, E = the lines, A = the source's stride (added to HL after
; each line; 0 repeats one source line, used with the cleared buffer to clear a
; screen block). Patches the column into $79D3 and the stride into $79E4, then
; for each line takes the line's address from ScreenLineTable and LDIRs D
; bytes. Destroys IX, BC, DE.
;
; Stage 1's CopyToScreen at $79CC is the same code.
;
; Witness: L1 7038 (rzx-r3, s3-right).
CopyToScreen:
  LD (CopyToScreenLine+$0017),A
  LD A,B
  LD (CopyToScreenLine+$0006),A
  LD B,$00
  LD IX,ScreenLineTable
  ADD IX,BC
  ADD IX,BC
  LD B,E
  LD C,D
CopyToScreenLine:
  PUSH BC
  PUSH HL
  LD A,(IX+$00)
  ADD A,$00
  LD E,A
  LD D,(IX+$01)
  INC IX
  INC IX
  LD B,$00
  LDIR
  POP HL
  LD B,$00
  LD C,$00
  ADD HL,BC
  POP BC
  DJNZ CopyToScreenLine
  RET

  ORG $7F43

; For an actor with a shift (+$11 = 1-7): copy its sprite to $7640 and shift it
; right
;
; IY = the actor record. +$11 = 0 or $64 and up: nothing. Else copies the
; sprite (+4/+5, +2 bytes wide, +3 lines) to $7640 with a zero byte added to
; each line, then shifts each line right by +$11 pixels with the routine
; ShiftRoutines[+$11] (patched into PreShiftCall). Called by $A828 for every
; actor drawn.
;
; In stage 3 the shift was 1-$63 in 476 passes (the copy from $7F4C ran 476
; times) and $64 and up in 669 (rzx-r3, s3-right).
;
; Stage 1's PreShiftSprite at $7F4D is the same code.
;
; Witness: L1 31566 (rzx-r3, s3-right).
PreShiftSprite:
  LD A,(IY+$11)
  CP $00
  RET Z
  CP $64
  RET NC
  LD B,(IY+$03)
  LD L,(IY+$04)
  LD H,(IY+$05)
  LD DE,DigitBuffer
PreShiftCopyLine:
  PUSH BC
  LD C,(IY+$02)
  LD B,$00
  LDIR
  XOR A
  LD (DE),A
  INC DE
  POP BC
  DJNZ PreShiftCopyLine
  LD C,(IY+$11)
  SLA C
  LD B,$00
  LD HL,ShiftRoutines
  ADD HL,BC
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD (PreShiftCall+$0001),DE
  LD HL,DigitBuffer
  LD B,(IY+$03)
PreShiftLine:
  PUSH BC
PreShiftCall:
  CALL $0000              ; CALL ShiftRoutines[+$11], patched
  POP BC
  DJNZ PreShiftLine
  RET

; The shift routine for 1-7 pixels (entry 0 unused)
;
; Stage 1's ShiftRoutines at $7F90 (found through the operands of the matched
; routines); the size and shape given here are stage 3's, from its bytes and
; readers.
ShiftRoutines:
  DEFW $0000,ShiftLine1,ShiftLine2,ShiftLine3,ShiftLine4,ShiftLine5,ShiftLine6,ShiftLine7

; Shift one line of (IY+2)+1 bytes at HL one pixel right; HL moves past it
;
; Stage 1's ShiftLine1 at $7FA0 is the same code.
;
; Witness: L1 13944 (rzx-r3).
ShiftLine1:
  LD B,(IY+$02)
  SRL (HL)
  INC L
ShiftLine1Byte:
  RR (HL)
  INC L
  DJNZ ShiftLine1Byte
  RET

; Two pixels: ShiftLine1 twice
;
; ShiftRoutines' entry 2.
;
; Witness: L1 3780 (rzx-r3).
ShiftLine2:
  PUSH HL
  CALL ShiftLine1
  POP HL
  JP ShiftLine1

; Three pixels: ShiftLine1 three times
;
; ShiftRoutines' entry 3. No sprite with a shift of 3 was drawn in the
; recordings.
;
; Not executed in any recording (the recordings checked: rzx-r3, s3-right);
; known only from the code.
ShiftLine3:
  PUSH HL
  CALL ShiftLine1
  POP HL
  PUSH HL
  CALL ShiftLine1
  POP HL
  JP ShiftLine1

; Four pixels: RLD along the line
;
; Stage 1's ShiftLine4 at $7FBF is the same code.
;
; Witness: L1 6216 (rzx-r3).
ShiftLine4:
  LD B,(IY+$02)
  INC B
  XOR A
ShiftLine4Byte:
  RRD
  INC L
  DJNZ ShiftLine4Byte
  RET

; Five pixels: ShiftLine4, then ShiftLine1
;
; ShiftRoutines' entry 5.
;
; Not executed in any recording (the recordings checked: rzx-r3, s3-right);
; known only from the code.
ShiftLine5:
  PUSH HL
  CALL ShiftLine4
  POP HL
  JP ShiftLine1

; Six pixels: ShiftLine4, then ShiftLine1 twice
;
; ShiftRoutines' entry 6.
;
; Witness: L1 3192 (rzx-r3).
ShiftLine6:
  PUSH HL
  CALL ShiftLine4
  POP HL
  PUSH HL
  CALL ShiftLine1
  POP HL
  JP ShiftLine1

; Seven pixels: ShiftLine4, then ShiftLine1 three times
;
; ShiftRoutines' entry 7.
;
; Not executed in any recording (the recordings checked: rzx-r3, s3-right);
; known only from the code.
ShiftLine7:
  PUSH HL
  CALL ShiftLine4
  POP HL
  PUSH HL
  CALL ShiftLine1
  POP HL
  PUSH HL
  CALL ShiftLine1
  POP HL
  JP ShiftLine1

  ORG $8633

; Plot one sprite row 1 byte wide into the play buffer
;
; HL = the sprite's bytes, DE = the buffer address. ORs (HL) into (DE) (no
; mask: the buffer is cleared every pass),
;
; then HL + 1 and DE + 32 (the next pixel line). One of the row plotters of
; RowPlotters $87CD, called once a row by
;
; the sprite drawer at $A8A8. The plotters 1-7 bytes wide all work so; the
; mirrored ones read the row's bytes in
;
; order and write them right to left through the bit-reversal table at $FA00
; (resident), so a sprite faces left.
;
; Stage 1's PlotRow1 at $8776 is the same code.
;
; Witness: L1 1118 (rzx-r3).
PlotRow1:
  LD A,(DE)
  OR (HL)
  LD (DE),A
  INC HL
  LD A,E
  ADD A,$20
  LD E,A
  RET NC
  INC D
  RET

; Plot one sprite row 1 byte wide, mirrored
;
; As PlotRow1, the byte bit-reversed through the table $FA00 (B = $FA, C = the
; byte).
;
; Stage 1's PlotRow1Mirrored at $8781 is the same code.
;
; Not executed in any recording (the recordings checked: rzx-r3, s3-right);
; known only from the code.
PlotRow1Mirrored:
  PUSH BC
  LD B,$FA
  LD C,(HL)
  LD A,(BC)
  LD C,A
  LD A,(DE)
  OR C
  LD (DE),A
  INC HL
  POP BC
  LD A,E
  ADD A,$20
  LD E,A
  RET NC
  INC D
  RET

; Plot one sprite row 2 bytes wide
;
; ORs 2 bytes from HL into DE, DE+1; then DE + 31 (the next line's first
; column).
;
; Stage 1's PlotRow2 at $8793 is the same code.
;
; Witness: L1 117953 (rzx-r3, s3-right).
PlotRow2:
  LD A,(DE)
  OR (HL)
  LD (DE),A
  INC HL
  INC E
  LD A,(DE)
  OR (HL)
  LD (DE),A
  INC HL
  LD A,E
  ADD A,$1F
  LD E,A
  RET NC
  INC D
  RET

; Plot one sprite row 2 bytes wide, mirrored
;
; DE = the row's rightmost byte: each byte bit-reversed through $FA00 and
; written leftwards; then DE + 33.
;
; Stage 1's PlotRow2Mirrored at $87A3 is the same code.
;
; Witness: L1 29387 (rzx-r3).
PlotRow2Mirrored:
  PUSH BC
  LD B,$FA
  LD C,(HL)
  LD A,(BC)
  LD C,A
  LD A,(DE)
  OR C
  LD (DE),A
  INC HL
  DEC E
  LD C,(HL)
  LD A,(BC)
  LD C,A
  LD A,(DE)
  OR C
  LD (DE),A
  INC HL
  POP BC
  LD A,E
  ADD A,$21
  LD E,A
  RET NC
  INC D
  RET

; Plot one sprite row 3 bytes wide
;
; Stage 1's PlotRow3 at $87BD is the same code.
;
; Witness: L1 33520 (rzx-r3, s3-right).
PlotRow3:
  LD A,(DE)
  OR (HL)
  LD (DE),A
  INC HL
  INC E
  LD A,(DE)
  OR (HL)
  LD (DE),A
  INC HL
  INC E
  LD A,(DE)
  OR (HL)
  LD (DE),A
  INC HL
  LD A,E
  ADD A,$1E
  LD E,A
  RET NC
  INC D
  RET

; Plot one sprite row 3 bytes wide, mirrored
;
; Stage 1's PlotRow3Mirrored at $87D2 is the same code.
;
; Witness: L1 23080 (rzx-r3, s3-right).
PlotRow3Mirrored:
  PUSH BC
  LD B,$FA
  LD C,(HL)
  LD A,(BC)
  LD C,A
  LD A,(DE)
  OR C
  LD (DE),A
  INC HL
  DEC E
  LD C,(HL)
  LD A,(BC)
  LD C,A
  LD A,(DE)
  OR C
  LD (DE),A
  INC HL
  DEC E
  LD C,(HL)
  LD A,(BC)
  LD C,A
  LD A,(DE)
  OR C
  LD (DE),A
  INC HL
  POP BC
  LD A,E
  ADD A,$22
  LD E,A
  RET NC
  INC D
  RET

; Plot one sprite row 4 bytes wide
;
; Stage 1's PlotRow4 at $87F4 is the same code.
;
; Witness: L1 28405 (rzx-r3, s3-right).
PlotRow4:
  LD A,(DE)
  OR (HL)
  LD (DE),A
  INC HL
  INC E
  LD A,(DE)
  OR (HL)
  LD (DE),A
  INC HL
  INC E
  LD A,(DE)
  OR (HL)
  LD (DE),A
  INC HL
  INC E
  LD A,(DE)
  OR (HL)
  LD (DE),A
  INC HL
  LD A,E
  ADD A,$1D
  LD E,A
  RET NC
  INC D
  RET

; Plot one sprite row 4 bytes wide, mirrored
;
; Stage 1's PlotRow4Mirrored at $880E is the same code.
;
; Witness: L1 9890 (rzx-r3, s3-right).
PlotRow4Mirrored:
  PUSH BC
  LD B,$FA
  LD C,(HL)
  LD A,(BC)
  LD C,A
  LD A,(DE)
  OR C
  LD (DE),A
  INC HL
  DEC E
  LD C,(HL)
  LD A,(BC)
  LD C,A
  LD A,(DE)
  OR C
  LD (DE),A
  INC HL
  DEC E
  LD C,(HL)
  LD A,(BC)
  LD C,A
  LD A,(DE)
  OR C
  LD (DE),A
  INC HL
  DEC E
  LD C,(HL)
  LD A,(BC)
  LD C,A
  LD A,(DE)
  OR C
  LD (DE),A
  INC HL
  POP BC
  LD A,E
  ADD A,$23
  LD E,A
  RET NC
  INC D
  RET

; Plot one sprite row 5 bytes wide
;
; No 5-byte-wide sprite was drawn in the stage-1 recordings.
;
; Stage 1's PlotRow5 at $8838 is the same code.
;
; Witness: L1 10815 (rzx-r3, s3-right).
PlotRow5:
  LD A,(DE)
  OR (HL)
  LD (DE),A
  INC HL
  INC E
  LD A,(DE)
  OR (HL)
  LD (DE),A
  INC HL
  INC E
  LD A,(DE)
  OR (HL)
  LD (DE),A
  INC HL
  INC E
  LD A,(DE)
  OR (HL)
  LD (DE),A
  INC HL
  INC E
  LD A,(DE)
  OR (HL)
  LD (DE),A
  INC HL
  LD A,E
  ADD A,$1C
  LD E,A
  RET NC
  INC D
  RET

; Plot one sprite row 5 bytes wide, mirrored
;
; Stage 1's PlotRow5Mirrored at $8857 is the same code.
;
; Witness: L1 2157 (rzx-r3).
PlotRow5Mirrored:
  PUSH BC
  LD B,$FA
  LD C,(HL)
  LD A,(BC)
  LD C,A
  LD A,(DE)
  OR C
  LD (DE),A
  INC HL
  DEC E
  LD C,(HL)
  LD A,(BC)
  LD C,A
  LD A,(DE)
  OR C
  LD (DE),A
  INC HL
  DEC E
  LD C,(HL)
  LD A,(BC)
  LD C,A
  LD A,(DE)
  OR C
  LD (DE),A
  INC HL
  DEC E
  LD C,(HL)
  LD A,(BC)
  LD C,A
  LD A,(DE)
  OR C
  LD (DE),A
  INC HL
  DEC E
  LD C,(HL)
  LD A,(BC)
  LD C,A
  LD A,(DE)
  OR C
  LD (DE),A
  INC HL
  POP BC
  LD A,E
  ADD A,$24
  LD E,A
  RET NC
  INC D
  RET

; Plot one sprite row 6 bytes wide
;
; Used by the 6-byte frames (RowPlotters' word for width 6 at $87E5): in stage
; 3 the dragon's breath (BreathSprites $CCD9, the full cloud 6 x 44).
;
; Stage 1's PlotRow6 at $8889 is the same code.
;
; Witness: L1 1672 (rzx-r3).
PlotRow6:
  LD A,(DE)
  OR (HL)
  LD (DE),A
  INC HL
  INC E
  LD A,(DE)
  OR (HL)
  LD (DE),A
  INC HL
  INC E
  LD A,(DE)
  OR (HL)
  LD (DE),A
  INC HL
  INC E
  LD A,(DE)
  OR (HL)
  LD (DE),A
  INC HL
  INC E
  LD A,(DE)
  OR (HL)
  LD (DE),A
  INC HL
  INC E
  LD A,(DE)
  OR (HL)
  LD (DE),A
  INC HL
  LD A,E
  ADD A,$1B
  LD E,A
  RET NC
  INC D
  RET

; Plot one sprite row 6 bytes wide, mirrored
;
; Stage 1's PlotRow6Mirrored at $88AD is the same code.
;
; Not executed in any recording (the recordings checked: rzx-r3, s3-right);
; known only from the code.
PlotRow6Mirrored:
  PUSH BC
  LD B,$FA
  LD C,(HL)
  LD A,(BC)
  LD C,A
  LD A,(DE)
  OR C
  LD (DE),A
  INC HL
  DEC E
  LD C,(HL)
  LD A,(BC)
  LD C,A
  LD A,(DE)
  OR C
  LD (DE),A
  INC HL
  DEC E
  LD C,(HL)
  LD A,(BC)
  LD C,A
  LD A,(DE)
  OR C
  LD (DE),A
  INC HL
  DEC E
  LD C,(HL)
  LD A,(BC)
  LD C,A
  LD A,(DE)
  OR C
  LD (DE),A
  INC HL
  DEC E
  LD C,(HL)
  LD A,(BC)
  LD C,A
  LD A,(DE)
  OR C
  LD (DE),A
  INC HL
  DEC E
  LD C,(HL)
  LD A,(BC)
  LD C,A
  LD A,(DE)
  OR C
  LD (DE),A
  INC HL
  POP BC
  LD A,E
  ADD A,$25
  LD E,A
  RET NC
  INC D
  RET

; Plot one sprite row 7 bytes wide (no mirrored form)
;
; The widest plotter; RowPlotters has no mirrored 7-byte entry (index 15 is
; $8629).
;
; Stage 1's PlotRow7 at $88E7 is the same code.
;
; Not executed in any recording (the recordings checked: rzx-r3, s3-right);
; known only from the code.
PlotRow7:
  LD A,(DE)
  OR (HL)
  LD (DE),A
  INC HL
  INC E
  LD A,(DE)
  OR (HL)
  LD (DE),A
  INC HL
  INC E
  LD A,(DE)
  OR (HL)
  LD (DE),A
  INC HL
  INC E
  LD A,(DE)
  OR (HL)
  LD (DE),A
  INC HL
  INC E
  LD A,(DE)
  OR (HL)
  LD (DE),A
  INC HL
  INC E
  LD A,(DE)
  OR (HL)
  LD (DE),A
  INC HL
  INC E
  LD A,(DE)
  OR (HL)
  LD (DE),A
  INC HL
  LD A,E
  ADD A,$1A
  LD E,A
  RET NC
  INC D
  RET

; The row plotter of each sprite width: word 2 x width + 1 when mirrored
;
; Read by the sprite drawer at $A8C8 (LD BC,RowPlotters): index 2 x width +
; (facing left). Width 0 and the mirrored
;
; width 7 hold $8629 (a hang loop: border flicker and KeyHook forever), never
; reached with a valid frame.
;
; Stage 1's RowPlotters at $8910 (found through the operands of the matched
; routines); the size and shape given here are stage 3's, from its bytes and
; readers.
RowPlotters:
  DEFW HangFlashBorder,HangFlashBorder,PlotRow1,PlotRow1Mirrored,PlotRow2,PlotRow2Mirrored,PlotRow3,PlotRow3Mirrored
  DEFW PlotRow4,PlotRow4Mirrored,PlotRow5,PlotRow5Mirrored,PlotRow6,PlotRow6Mirrored,PlotRow7,HangFlashBorder

  ORG $89A4

; Draw a row-packed picture into a buffer
;
; HL = the picture, DE = the buffer address of its first line, B = its lines.
; Each line is one byte, the bytes to
;
; copy in its high nibble and the columns to skip in its low nibble, then those
; bytes; DE + 32 a line. Stage 3's
;
; two pictures are in this form: DragonPicture $C921 (DrawDragon, $8899) and
; ThronePicture $C44D (ThroneBossStep, $952D).
;
; Stage 1's DrawRowPicture at $8B03 is the same code.
;
; Witness: L1 46610 (rzx-r3).
DrawRowPicture:
  PUSH BC
  PUSH DE
  LD A,(HL)
  AND $0F
  ADD A,E
  LD E,A
  LD A,(HL)
  SRL A
  SRL A
  SRL A
  SRL A
  LD C,A
  LD B,$00
  INC HL
  LDIR
  POP DE
  EX DE,HL
  LD BC,$0020
  ADD HL,BC
  EX DE,HL
  POP BC
  DJNZ DrawRowPicture
  RET

  ORG $8ADE

; Fill a rectangle of the screen's attributes (5 bytes after the CALL)
;
; The 5 bytes after the CALL: the column, the pixel line (/8 = the cell row),
; the width, the height in cells, the
;
; attribute. Returns after them. The game-over screen $78BA and $78C2 use it.
;
; Stage 1's FillAttributes at $8C3D is the same code.
;
; Witness: L1 261 (rzx-r3, s3-right).
FillAttributes:
  POP IX
  LD BC,$0005
  ADD IX,BC
  PUSH IX
  LD B,(IX-$05)
  LD C,(IX-$04)
  LD D,(IX-$03)
  LD E,(IX-$02)
  LD A,(IX-$01)
  PUSH DE
  LD DE,Attributes
  CALL CellAddress
  POP BC
  LD DE,$0020
FillAttributesRow:
  PUSH BC
  PUSH HL
FillAttributesCell:
  LD (HL),A
  INC HL
  DJNZ FillAttributesCell
  POP HL
  ADD HL,DE
  POP BC
  DEC C
  JR NZ,FillAttributesRow
  RET

; Fill a rectangle of the shadow attributes $6D00 (5 bytes after the CALL)
;
; As FillAttributes into the shadow; StageSetUp paints the HUD's boxes with it.
;
; Stage 1's FillShadowAttributes at $8C6D is the same code.
;
; Witness: L1 8 (rzx-r3, s3-right).
FillShadowAttributes:
  POP IX
  LD BC,$0005
  ADD IX,BC
  PUSH IX
  LD B,(IX-$05)
  LD C,(IX-$04)
  LD D,(IX-$03)
  LD E,(IX-$02)
  LD A,(IX-$01)
  PUSH DE
  LD DE,ShadowAttributes
  CALL CellAddress
  POP BC
  LD DE,$0020
FillShadowRow:
  PUSH BC
  PUSH HL
FillShadowCell:
  LD (HL),A
  INC HL
  DJNZ FillShadowCell
  POP HL
  ADD HL,DE
  POP BC
  DEC C
  JR NZ,FillShadowRow
  RET

; Copy the whole shadow $6D00-$6FFF to the attributes after a HALT
;
; Stage 1's ShowShadowAttributes at $8C9D is the same code.
;
; Witness: L1 4 (rzx-r3, s3-right).
ShowShadowAttributes:
  LD HL,ShadowAttributes
  LD DE,Attributes
  LD BC,$0300
  HALT
  LDIR
  RET

; Copy the shadow attributes of the open cells to the screen, then the buffer;
; after a room change fade the old room's colours in
;
; Every pass from MainLoop. RestoreAttributes 0: for the 18 x 28 cells of the
; play area, a cell whose room cell ($7282 on) is 0 (open) gets the shadow's
; attribute ($6DC2 on) on the screen ($58C2 on); the solid cells keep the
; scenery's colours; then $A634 and CopyBuffer. RestoreAttributes 1 (after a
; room change, 37 times): RestoreAttributes = 0, CopyBuffer, $A634, a HALT,
; then every cell gets the shadow's attribute when open, else the old room's
; colour from RoomAttributesCell ($7042 on).
;
; Stage 1's UpdateAttributes ($8CAA) has the same job; tools/stage_names.py
; found no same code (names.err).
;
; Witness: L1 6278 (rzx-r3, s3-right).
UpdateAttributes:
  LD A,(RestoreAttributes)
  CP $01
  JP Z,RestoreRoomAttributes
  LD DE,Attributes+194
  LD HL,PlayAttributesCell
  LD IX,CellsPlay
  LD B,$12
UpdateAttributesRow:
  PUSH BC
  LD B,$1C
UpdateAttributesCell:
  LD A,(IX+$00)
  CP $00
  JR NZ,UpdateAttributesNext
  LD A,(HL)
  LD (DE),A
UpdateAttributesNext:
  INC DE
  INC HL
  INC IX
  DJNZ UpdateAttributesCell
  LD BC,$0004
  ADD HL,BC
  EX DE,HL
  ADD HL,BC
  EX DE,HL
  ADD IX,BC
  POP BC
  DJNZ UpdateAttributesRow
  CALL RestoreMasts
  CALL CopyBuffer
  RET
RestoreRoomAttributes:
  XOR A                   ; RestoreAttributes 1: the whole play area once,
                          ; solid cells from RoomAttributes
  LD (RestoreAttributes),A
  CALL CopyBuffer
  CALL RestoreMasts
  LD IX,Attributes+194
  LD HL,PlayAttributesCell
  LD IY,RoomAttributesCell
  LD DE,CellsPlay
  LD B,$12
  HALT
RestoreAttributesRow:
  PUSH BC
  LD B,$1C
RestoreAttributesCell:
  LD C,(IY+$00)
  LD A,(DE)
  OR A
  JR NZ,RestoreAttributesPut
  LD C,(HL)
RestoreAttributesPut:
  LD (IX+$00),C
  INC E
  INC IYL
  INC L
  INC IXL
  DJNZ RestoreAttributesCell
  LD BC,$0004
  ADD HL,BC
  ADD IY,BC
  ADD IX,BC
  EX DE,HL
  ADD HL,BC
  EX DE,HL
  POP BC
  DJNZ RestoreAttributesRow
  RET

  ORG $96DF

; One step of the colour fade: each cell's ink one nearer its shadow attribute
;
; Over the 576 attributes from $58C2 (row 6 column 2) against the shadow $6DC2:
; where the shadow is non-zero, on odd
;
; passes the ink goes down one, on even ones up one toward the shadow's ink
; (with the shadow's paper). StageFadeIn
;
; calls it 35 times.
;
; Stage 1's FadeInStep at $9325 is the same code.
;
; Witness: L1 70 (rzx-r3, s3-right).
FadeInStep:
  LD HL,Attributes+194
  LD DE,PlayAttributesCell
  LD BC,$0240
FadeCell:
  PUSH BC
  LD A,(DE)
  CP $00
  JR Z,FadeNext
  LD A,(PassCounter)
  AND $01
  JR Z,FadeUp
  DEC (HL)
  JR FadeNext
FadeUp:
  LD A,(DE)
  AND $07
  CP (HL)
  JR Z,FadeNext
  INC (HL)
  LD A,(DE)
  AND $38
  OR (HL)
  LD (HL),A
FadeNext:
  INC DE
  INC HL
  POP BC
  DEC BC
  LD A,B
  OR C
  JR NZ,FadeCell
  RET

  ORG $99B1

; Turn the cells into tile kinds and list the open runs as spans for CopyBuffer
;
; Patches $99E4 with the tile kinds' address ($5B0A + the header word $5B00).
; Each cell's tile number becomes its
;
; kind (0 open, else solid scenery). Each run of open cells in a row becomes a
; span (AddSpan): 6 bytes from $76A0:
;
; the length in cells, 0, the play buffer's address, the screen's address.
; SpanCount = the spans.
;
; Stage 1's BuildSpans at $99E9 is the same code.
;
; Witness: L1 39 (rzx-r3, s3-right).
BuildSpans:
  LD HL,(PlayBuffer)
  LD BC,PlayBuffer+10
  ADD HL,BC
  LD (BuildSpansKinds+$0001),HL
  PUSH IX
  LD HL,$0000
  LD (SpanCount),HL
  LD A,$02
  LD (CellColumn),A
  XOR A
  LD (SpanRow),A
  LD IY,CellsPlay
  LD IX,SpanTable
  LD B,$12
BuildSpansRow:
  PUSH BC
  LD B,$1C
  XOR A
  LD (SpanOpen),A
BuildSpansCell:
  PUSH BC
  LD C,(IY+$00)
  LD B,$00
BuildSpansKinds:
  LD HL,$0000             ; LD HL,n: n = the tile kinds' address
  ADD HL,BC
  LD A,(HL)
  LD (IY+$00),A
  INC IY
  CP $00
  JR Z,BuildSpansOpen
  XOR A
  LD (SpanOpen),A
  JR BuildSpansNext
BuildSpansOpen:
  LD A,(SpanOpen)
  CP $01
  JR NZ,BuildSpansStart
  INC (IX-$06)
  JR BuildSpansNext
BuildSpansStart:
  LD A,$01
  LD (SpanOpen),A
  CALL AddSpan
  LD HL,(SpanCount)
  INC HL
  LD (SpanCount),HL
BuildSpansNext:
  POP BC
  LD A,(CellColumn)
  INC A
  LD (CellColumn),A
  DJNZ BuildSpansCell
  POP BC
  INC IY
  INC IY
  INC IY
  INC IY
  LD A,$02
  LD (CellColumn),A
  LD A,(SpanRow)
  INC A
  LD (SpanRow),A
  DJNZ BuildSpansRow
  POP IX
  RET

; Open a span of 1 cell at the current cell (IX = the next span record)
;
; Length 1, then the buffer's address $5B00 + SpanRow x 256 + CellColumn and
; the screen's ($FB60 + SpanRow x 16,
;
; i.e. ScreenLineTable from line 48, + CellColumn); IX + 6.
;
; Stage 1's AddSpan at $9A6E is the same code.
;
; Witness: L1 914 (rzx-r3, s3-right).
AddSpan:
  LD (IX+$00),$01
  LD (IX+$01),$00
  LD A,(SpanRow)
  LD H,A
  LD L,$00
  LD A,(CellColumn)
  LD C,A
  LD B,$00
  ADD HL,BC
  LD BC,PlayBuffer
  ADD HL,BC
  LD (IX+$02),L
  LD (IX+$03),H
  LD A,(SpanRow)
  SLA A
  SLA A
  SLA A
  LD L,A
  LD H,$00
  ADD HL,HL
  LD BC,ScreenLineTable+96
  ADD HL,BC
  LD E,(HL)
  INC HL
  LD D,(HL)
  EX DE,HL
  LD A,(CellColumn)
  LD C,A
  LD B,$00
  ADD HL,BC
  LD (IX+$04),L
  LD (IX+$05),H
  LD DE,$0006
  ADD IX,DE
  RET

; Clear the play buffer $5B00-$6CFF with PUSH HL (DI)
;
; SP = $6D00, 144 x 16 PUSHes of 0 (4608 bytes); SP saved in SavedSP.
; Interrupts off meanwhile (DI ... EI).
;
; Stage 1's ClearBuffer at $9AB5 is the same code.
;
; Witness: L1 6322 (rzx-r3, s3-right).
ClearBuffer:
  DI
  LD (SavedSP),SP
  LD HL,$0000
  LD SP,ShadowAttributes
  LD B,$90
ClearBufferLoop:
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  DJNZ ClearBufferLoop
  LD SP,(SavedSP)
  EI
  RET

; Copy the open spans of the play buffer to the screen (an LDI chain cut by a
; patched JP)
;
; SP walks the span table $76A0 (POP BC: the length, POP HL: the buffer, POP
; DE: the screen). For each span: patches
;
; the LD BC at $9B0D with 32 - the length, writes JP $9B0D into the LDI chain
; at $9AD1 + 2 x the length (saved at
;
; $9B18), the LD E at $9B11 with the screen address's low byte; copies 8 lines
; (LDIs, then HL + 32 - length, E
;
; back, D + 1); puts ED A0 ED back. SpanCount spans; interrupts off meanwhile.
;
; Stage 1's CopyBuffer at $9ADA, the same instructions; the operands that
; differ ($9AAB, $9AB5, $9ABA, $9ABE, $9AC4, $9ACC) are addresses: SpanTable
; $76E0 and the routine's own patched instructions ($9B0E, $9AD1, $9B18,
; $9B12), all stage 3's.
;
; Witness: L1 6280 (rzx-r3, s3-right).
CopyBuffer:
  DI
  LD HL,(SpanCount)
  PUSH HL
  LD (SavedSP),SP
  LD SP,SpanTable
CopySpan:
  POP BC
  LD A,$20
  SUB C
  LD L,A
  LD H,$00
  LD (CopyLineEnd+$0001),HL
  SLA C
  LD HL,CopyChain
  ADD HL,BC
  LD (CopySpanRestore+$0001),HL
  LD (HL),$C3
  INC HL
  LD (HL),$0D
  INC HL
  LD (HL),$9B
  POP HL
  POP DE
  LD A,E
  LD (CopyLineE+$0001),A
  LD A,$08
CopyChain:
  LDI                     ; 30 LDIs, cut by the JP patched over the one after
                          ; the span's length
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
CopyLineEnd:
  LD BC,$0000             ; LD BC,n: n = 32 - the length
  ADD HL,BC
CopyLineE:
  LD E,$00                ; LD E,n: n = the span's screen address's low byte
  INC D
  DEC A
  JR NZ,CopyChain
CopySpanRestore:
  LD HL,$0000             ; LD HL,n: n = where the JP was put
  LD (HL),$ED
  INC HL
  LD (HL),$A0
  INC HL
  LD (HL),$ED
  LD HL,(SpanCount)
  DEC HL
  LD (SpanCount),HL
  LD A,L
  OR H
  JR NZ,CopySpan
  LD SP,(SavedSP)
  POP HL
  LD (SpanCount),HL
  EI
  RET

  ORG $9FC7

; Fill the attributes of screen rows 6-23 with 0 (black on black)
;
; Fills $58C0-$5AFF (the play area's 576 attributes) with 0 before a room is
; built. Called by the room builder $9853.
;
; Stage 1's BlackOutPlayArea at $A057 is the same code.
;
; Witness: L1 40 (rzx-r3, s3-right).
BlackOutPlayArea:
  LD HL,Attributes+192
  LD DE,Attributes+193
  LD BC,$023F
  LD (HL),$00
  LDIR
  RET

  ORG $A7DD

; Draw every visible actor into the play buffer, in two passes (+$0F bit 7
; last)
;
; First pass: the used records with +$0F bits 6 and 7 clear; second pass: those
; with bit 7 (drawn over the others). Each: ClipActor then DrawActorSprite. Bit
; 6 is never drawn.
;
; Stage 1's DrawActors at $A5DF is the same code.
;
; Witness: L1 6280 (rzx-r3, s3-right).
DrawActors:
  LD B,$0E
  LD IY,HeroRecord
DrawActorsLoop:
  PUSH BC
  LD A,(IY+$00)
  CP $FF
  JR Z,DrawActorsNext
  BIT 6,(IY+$0F)
  JR NZ,DrawActorsNext
  BIT 7,(IY+$0F)
  JR NZ,DrawActorsNext
  CALL ClipActor
  CALL DrawActorSprite
DrawActorsNext:
  POP BC
  LD DE,$0012
  ADD IY,DE
  DJNZ DrawActorsLoop
  LD B,$0E
  LD IY,HeroRecord
DrawActorsTopLoop:
  PUSH BC
  LD A,(IY+$00)
  CP $FF
  JR Z,DrawActorsTopNext
  BIT 7,(IY+$0F)
  JR Z,DrawActorsTopNext
  CALL ClipActor
  CALL DrawActorSprite
DrawActorsTopNext:
  POP BC
  LD DE,$0012
  ADD IY,DE
  DJNZ DrawActorsTopLoop
  RET

; The actor's visible lines, buffer address and frame address
;
; IY = the actor. Output: B = the lines to draw (0 none), DE = the play-buffer
; address, HL = the frame. Y $C8 and up (above the top): ClipActorTop. Y
; $90-$C7 (below the play area): B = 0. Else B = the height cut at line $90;
; $7F43 makes the shifted copy at $7640 when +$11 is 1-99, and HL is then
; $7640, else the frame +4/+5.
;
; Stage 1's ClipActor at $A62A is the same code.
;
; Witness: L1 31568 (rzx-r3, s3-right).
ClipActor:
  LD A,(IY+$01)
  CP $C8
  JP NC,ClipActorTop
  CP $90
  JP NC,ClipActorOff
  LD A,(IY+$03)
  LD B,A
  ADD A,(IY+$01)
  CP $91
  JR C,ClipActorShift
  LD A,$90
  SUB (IY+$01)
  LD B,A
ClipActorShift:
  PUSH BC
  CALL PreShiftSprite
  CALL BufferAddressDE
  POP BC
  LD HL,DigitBuffer
  LD A,(IY+$11)
  CP $00
  JR Z,ClipActorFrame
  CP $64
  RET C
ClipActorFrame:
  LD L,(IY+$04)
  LD H,(IY+$05)
  RET

; DE = $5B00 + Y x 32 + X of the actor IY
;
; Stage 1's BufferAddressDE at $A664 is the same code.
;
; Witness: L1 31566 (rzx-r3, s3-right).
BufferAddressDE:
  LD L,(IY+$01)
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD C,(IY+$00)
  LD B,$00
  ADD HL,BC
  LD BC,PlayBuffer
  ADD HL,BC
  EX DE,HL
  RET

; ClipActorTop
;
; Used by the routine at ClipActor.
ClipActorTop:
  LD B,$00                ; Above the top: draw the lines from line 0, skip the
                          ; frame's first rows
  LD A,(IY+$03)
  ADD A,(IY+$01)
  RET NC
  RET Z
  LD B,A
  LD A,(IY+$00)
  LD E,A
  LD D,$00
  LD HL,PlayBuffer
  ADD HL,DE
  PUSH HL
  LD L,(IY+$04)
  LD H,(IY+$05)
  LD A,(IY+$03)
  SUB B
  JR Z,ClipActorTopDone
  LD D,$00
  LD E,(IY+$02)
ClipActorTopSkip:
  ADD HL,DE
  DEC A
  JR NZ,ClipActorTopSkip
ClipActorTopDone:
  POP DE
  RET
; This entry point is used by the routine at ClipActor.
ClipActorOff:
  LD B,$00                ; B = 0: nothing to draw
  RET

; Draw B lines of the actor's frame into the play buffer, then colour it
;
; Input: B lines, DE = the buffer, HL = the frame (rows of +2 bytes, top first,
; no mask). +9 bit 0: copied opaque (DrawActorOpaque). Else ORed in by a row
; routine from the table $87CD (4 bytes a width 0-7: the right-facing and the
; left-facing routine); the left-facing routines mirror the bytes through the
; resident bit-reverse table $FA00 and step left, so a left-facing actor's X is
; its right column. A shifted copy (+$11 1-99) is one byte wider. The routine
; is written into RowDrawCall. Then ColourActor.
;
; Stage 1's DrawActorSprite at $A6AA is the same code.
;
; Witness: L1 31568 (rzx-r3, s3-right).
DrawActorSprite:
  LD A,B
  CP $00
  RET Z
  BIT 0,(IY+$09)
  JP NZ,DrawActorOpaque
  PUSH HL
  PUSH BC
  LD L,(IY+$02)
  LD A,(IY+$11)
  CP $00
  JR Z,DrawActorSpriteRoutine
  CP $64
  JR NC,DrawActorSpriteRoutine
  INC L
DrawActorSpriteRoutine:
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  LD BC,RowPlotters
  ADD HL,BC
  BIT 7,(IY+$09)
  JR Z,DrawActorSpriteSet
  INC HL
  INC HL
DrawActorSpriteSet:
  LD C,(HL)
  INC HL
  LD B,(HL)
  LD (RowDrawCall+$0001),BC
  POP BC
  POP HL
RowDrawCall:
  CALL $0000              ; CALL n: n = the row routine (written above)
  DJNZ RowDrawCall
  CALL ColourActor
  RET
DrawActorOpaque:
  LD C,(IY+$02)           ; LDIR each row of +2 bytes, 32 bytes a buffer line
DrawActorOpaqueLoop:
  PUSH BC
  PUSH DE
  LD B,$00
  LDIR
  POP DE
  EX DE,HL
  LD BC,$0020
  ADD HL,BC
  EX DE,HL
  POP BC
  DJNZ DrawActorOpaqueLoop
  CALL ColourActor
  RET

; Fill the actor's cells in the attribute shadow $6D00 with its attribute +$0C
;
; The cells under the actor (screen row Y / 8 + 6; the column X, or X - width +
; 1 facing left; width +2, + 1 when shifted, written into ColourWidth; the rows
; the lines cover, cut at line $90) get +$0C in the attribute shadow at $6D00.
; Nothing below the play area.
;
; Stage 1's ColourActor at $A6FF is the same code.
;
; Witness: L1 31558 (rzx-r3, s3-right).
ColourActor:
  LD C,(IY+$02)
  LD A,(IY+$11)
  CP $00
  JR Z,ColourActorWidth
  CP $64
  JR NC,ColourActorWidth
  INC C
ColourActorWidth:
  LD A,C
  LD (ColourWidth+$0001),A
  LD A,(IY+$01)
  CP $90
  RET NC
  ADD A,$30
  AND $F8
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  LD A,(IY+$00)
  BIT 7,(IY+$09)
  LD C,A
  JR Z,ColourActorAddress
  SUB (IY+$02)
  LD C,A
  INC C
  LD A,(IY+$11)
  CP $00
  JR Z,ColourActorAddress
  CP $64
  JR NC,ColourActorAddress
  INC C
ColourActorAddress:
  LD B,$00
  ADD HL,BC
  LD BC,ShadowAttributes
  ADD HL,BC
  LD E,(IY+$0C)
  LD A,(IY+$01)
  ADD A,(IY+$03)
  CP $90
  JR C,ColourActorHeight
  LD A,$90
  SUB (IY+$01)
  JR ColourActorRows
ColourActorHeight:
  LD A,(IY+$03)
ColourActorRows:
  LD D,A
  LD B,A
  SRL B
  SRL B
  SRL B
  AND $07
  LD C,A
  LD A,(IY+$01)
  AND $07
  JR Z,ColourActorRows2
  INC B
ColourActorRows2:
  LD A,(IY+$01)
  ADD A,D
  AND $07
  JP Z,ColourActorRow
  INC B
ColourActorRow:
  PUSH BC
ColourWidth:
  LD B,$00                ; LD B,n: n = the width in cells (written above)
  LD C,L
ColourActorCell:
  LD (HL),E
  INC L
  DJNZ ColourActorCell
  LD L,C
  LD BC,$0020
  ADD HL,BC
  POP BC
  DJNZ ColourActorRow
  RET

; +$0C = ItemInks[+$0B & 3] (not referenced)
;
; No code or table in the image refers to $A986.
;
; Stage 1's CycleItemInk at $A788 is the same code.
;
; Not executed in any recording (the recordings checked: rzx-r3, s3-right);
; known only from the code.
CycleItemInk:
  LD A,(IY+$0B)
  AND $03
  LD C,A
  LD B,$00
  LD HL,ItemInks
  ADD HL,BC
  LD A,(HL)
  LD (IY+$0C),A
  RET

; CycleItemInk's four attributes
;
; Stage 1's ItemInks at $A799 (found through the operands of the matched
; routines); the size and shape given here are stage 3's, from its bytes and
; readers.
ItemInks:
  DEFB $41,$42,$43,$42

; Free the actor when it is in the hero's column and cell row (not referenced)
;
; When the hero's X ($74E0) equals +0 and the hero's Y and +1 are in the same
; cell row: +0 = $FF and a jump to $B37A. No code or table in the image refers
; to $A99B.
;
; Stage 1's FreeIfOnHero at $A79D is the same code.
;
; Not executed in any recording (the recordings checked: rzx-r3, s3-right);
; known only from the code.
FreeIfOnHero:
  LD A,(HeroRecord)
  CP (IY+$00)
  RET NZ
  LD A,(HeroY)
  AND $F8
  LD B,A
  LD A,(IY+$01)
  AND $F8
  CP B
  RET NZ
  LD (IY+$00),$FF
  JP ReturnZ

  ORG $B238

; Copy the screen's attributes to the shadow at $6D00
;
; Stage 1's SaveAttributes at $B17F is the same code.
;
; Witness: L1 2 (rzx-r3, s3-right).
SaveAttributes:
  LD HL,Attributes
  LD DE,ShadowAttributes
  LD BC,$0300
  LDIR
  RET

  ORG $B3CC

; HL = the play-buffer address of the actor IY ($5B00 + line x 32 + column); DE
; = HL in
;
; Stage 1's BufferAddressHL at $B332 is the same code.
;
; Witness: L1 3773 (rzx-r3, s3-right).
BufferAddressHL:
  PUSH HL
  LD L,(IY+$01)
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD C,(IY+$00)
  LD B,$00
  ADD HL,BC
  LD BC,PlayBuffer
  ADD HL,BC
  POP DE
  RET

; HL = the attribute-shadow address of the actor IY ($6DC0 + line / 8 x 32 +
; column)
;
; The shadow's row 6 ($6DC0) is the play area's top row.
;
; Stage 1's AttrShadowAddress at $B349 is the same code.
;
; Witness: L1 3773 (rzx-r3, s3-right).
AttrShadowAddress:
  LD A,(IY+$01)
  AND $F8

; AttrShadowAddressA
;
; Used by the routine at UpdateBurst.
AttrShadowAddressA:
  LD L,A                  ; entry with A = the line rounded down to 8
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  LD C,(IY+$00)
  LD B,$00
  ADD HL,BC
  LD BC,PlayAttributes
  ADD HL,BC
  RET

  ORG $B406

; C = $44 or $45 (bright green, bright cyan) on alternate passes
;
; No CALL, JP or word in the image reaches it.
;
; Stage 1's ColourGreenCyan at $B36C is the same code.
;
; Not executed in any recording (the recordings checked: rzx-r3, s3-right);
; known only from the code.
ColourGreenCyan:
  LD A,(PassCounter)
  LD C,$44
  AND $01
  RET Z
  LD C,$45
  RET

; C = $42 or $43 (bright red, bright magenta) on alternate passes
;
; Stage 1's ColourRedMagenta at $B377 is the same code.
;
; Witness: L1 1239 (rzx-r3).
ColourRedMagenta:
  LD A,(PassCounter)
  LD C,$42
  AND $01
  RET Z
  LD C,$43
  RET

; C = $42 (bright red) or 6 (yellow) on alternate passes
;
; Stage 1's ColourRedYellow at $B382 is the same code.
;
; Witness: L1 735 (rzx-r3).
ColourRedYellow:
  LD A,(PassCounter)
  LD C,$42
  AND $01
  RET Z
  LD C,$06
  RET

; C = ColourCycle4[pass AND 3]: cyan, bright green, bright cyan, white
;
; Called from `$827C` and `$8285`.
;
; Witness: L1 66 (rzx-r3).
ColourCyanCycle:
  LD A,(PassCounter)
  AND $03
  LD C,A
  LD B,$00
  LD HL,ColourCycle4
  ADD HL,BC
  LD C,(HL)
  RET

; ColourCyanCycle's four attributes: 5, `$44`, `$45`, 7
;
; Read by ColourCyanCycle `$B427`.
ColourCycle4:
  DEFB $05,$44,$45,$07

; The actor IY's colour +$0C = GreenCycleColours[pass AND 7]
;
; Green and cyan, dim and bright. Called from `$91AD`.
;
; Witness: L1 553 (rzx-r3).
SetGreenCycleColour:
  LD A,(PassCounter)
  AND $07
  LD C,A
  LD B,$00
  LD HL,GreenCycleColours
  ADD HL,BC
  LD A,(HL)
  LD (IY+$0C),A
  RET

; SetGreenCycleColour's eight attributes: 4, 4, `$44`, 5, `$45`, `$45`, 5,
; `$44`
;
; Read by SetGreenCycleColour `$B439` (all 8 in rzx-r3).
GreenCycleColours:
  DEFB $04,$04,$44,$05,$45,$45,$05,$44

; Eight more attributes, the same cycle in red and magenta: no code reads them
;
; 2, 2, `$42`, 3, `$43`, `$43`, 3, `$42`. No operand points here
; (SetGreenCycleColour adds only pass AND 7 to `$B44A`) and rw3.py `$B452`
; `$B45A` gives 0 reads.
RedCycleColours:
  DEFB $02,$02,$42,$03,$43,$43,$03,$42

; C = $46 or $43 (bright yellow, bright magenta) on alternate passes
;
; Stage 1's ColourYellowMagenta at $B38D is the same code.
;
; Witness: L1 2567 (s3-right).
ColourYellowMagenta:
  LD A,(PassCounter)
  LD C,$46
  AND $01
  RET Z
  LD C,$43
  RET

; C = $45 or $44 on alternate passes
;
; No CALL, JP or word in the image reaches it.
;
; Stage 1's ColourCyanGreen at $B398 is the same code.
;
; Not executed in any recording (the recordings checked: rzx-r3, s3-right);
; known only from the code.
ColourCyanGreen:
  LD A,(PassCounter)
  LD C,$45
  AND $01
  RET Z
  LD C,$44
  RET

; C = the colour of the missile IY: type 2 ColourYellowMagenta, else
; MissileColours[pass AND 3]
;
; Called by DragonFlameActor ($9359).
;
; Stage 1's MissileColour at $B3A3 is the same code.
;
; Witness: L1 257 (rzx-r3).
MissileColour:
  LD A,(IY+$02)
  CP $02
  JP Z,ColourYellowMagenta
  LD A,(PassCounter)
  AND $03
  LD C,A
  LD B,$00
  LD HL,MissileColours
  ADD HL,BC
  LD C,(HL)
  RET

; bright red, bright magenta, bright red, magenta
;
; Stage 1's MissileColours at $B3B9 (found through the operands of the matched
; routines); the size and shape given here are stage 3's, from its bytes and
; readers.
MissileColours:
  DEFB $42,$43,$42,$03

; C = RedCycle4[pass AND 3]: bright red, bright magenta, bright yellow, magenta
; (no caller)
;
; No CALL, JP or word in the image reaches `$B48A` (its table's address is only
; in its own LD HL).
;
; Not executed in any recording (the recordings checked: rzx-r3, s3-right);
; known only from the code.
ColourRedCycle:
  LD A,(PassCounter)
  AND $03
  LD C,A
  LD B,$00
  LD HL,RedCycle4
  ADD HL,BC
  LD C,(HL)
  RET

; ColourRedCycle's four attributes: `$42`, `$43`, `$46`, 3; no recording read
; them (rw3.py: 0 reads)
RedCycle4:
  DEFB $42,$43,$46,$03

; The actor IY's colour +$0C = CycleColour $B4A3
;
; Stage 1's SetCycleColour at $B3BD is the same code.
;
; Witness: L1 4226 (rzx-r3, s3-right).
SetCycleColour:
  CALL CycleColour
  LD (IY+$0C),A
  RET

; A = CycleColours[pass AND 7]: bright cyan, green, magenta, red, blue, red,
; magenta, green
;
; Stage 1's CycleColour at $B3C4 is the same code.
;
; Witness: L1 5894 (rzx-r3, s3-right).
CycleColour:
  LD A,(PassCounter)
  AND $07
  LD C,A
  LD B,$00
  LD HL,CycleColours
  ADD HL,BC
  LD A,(HL)
  RET

; the colour cycle
;
; Stage 1's CycleColours at $B3D2 (found through the operands of the matched
; routines); the size and shape given here are stage 3's, from its bytes and
; readers.
CycleColours:
  DEFB $45,$44,$43,$42,$41,$42,$43,$44

; Four image descriptors: the image address, the width in bytes, the height in
; lines
;
; $EB20, $EB47, $EB6E and $EB95 (the four frames of DriftShotSprites), each 3 x
; 13. Read through HL from UpdatePathFlyer ($84B3).
;
; Stage 1's ImageDescriptors at $B3EA (found through the operands of the
; matched routines); the size and shape given here are stage 3's, from its
; bytes and readers.
ImageDescriptors:
  DEFB $20,$EB,$03,$0D
  DEFB $47,$EB,$03,$0D
  DEFB $6E,$EB,$03,$0D
  DEFB $95,$EB,$03,$0D

; Fill the attribute shadow under an image with C
;
; IY = the position, IX the image descriptor (+2 width, +3 height): (height / 8
; + 1) rows of the width.
;
; Stage 1's ColourSprite at $B40A is the same code.
;
; Witness: L1 3492 (rzx-r3, s3-right).
ColourSprite:
  PUSH BC
  CALL AttrShadowAddress
  POP BC
  LD DE,$0020
  LD B,(IX+$03)
  SRL B
  SRL B
  SRL B
  INC B
ColourSpriteRow:
  PUSH BC
  PUSH HL
  LD B,(IX+$02)
ColourSpriteCell:
  LD (HL),C
  INC L
  DJNZ ColourSpriteCell
  POP HL
  ADD HL,DE
  POP BC
  DJNZ ColourSpriteRow
  RET

; Copy an image to the play buffer at the actor's position (no mask)
;
; HL = the image, IX the descriptor (+2 width in bytes, +3 height in lines), IY
; the position (BufferAddressHL
;
; $B3CC). The bytes replace the buffer's: no mask, no OR.
;
; Stage 1's DrawSprite at $B42B is the same code.
;
; Witness: L1 925 (rzx-r3).
DrawSprite:
  CALL BufferAddressHL
  EX DE,HL
  LD B,(IX+$03)
DrawSpriteRow:
  PUSH BC
  PUSH DE
  LD C,(IX+$02)
  LD B,$00
  LDIR
  POP DE
  EX DE,HL
  LD BC,$0020
  ADD HL,BC
  EX DE,HL
  POP BC
  DJNZ DrawSpriteRow
  RET

; Copy an image mirrored left to right (through the bit-reverse table $FA00)
;
; As DrawSprite $B4EA, each row written from right to left and each byte
; reversed by the resident's 256-byte table
;
; at $FA00. Called by UpdateThrownAmmo ($803C), DrawShotFrame ($809B) and
; UpdateBolt ($8282).
;
; Stage 1's DrawSpriteMirrored at $B446 is the same code.
;
; Witness: L1 281 (rzx-r3).
DrawSpriteMirrored:
  CALL BufferAddressHL
  EX DE,HL
  LD B,(IX+$03)
DrawSpriteMirroredRow:
  PUSH BC
  PUSH DE
  LD A,E
  ADD A,(IX+$02)
  DEC A
  LD E,A
  LD B,(IX+$02)
DrawSpriteMirroredByte:
  PUSH BC
  LD B,$FA
  LD A,(HL)
  LD C,A
  LD A,(BC)
  LD (DE),A
  DEC DE
  INC HL
  POP BC
  DJNZ DrawSpriteMirroredByte
  POP DE
  EX DE,HL
  LD BC,$0020
  ADD HL,BC
  EX DE,HL
  POP BC
  DJNZ DrawSpriteMirroredRow
  RET

; ColourSprite $B4C9 for a mirrored image (filled leftwards from its right
; edge)
;
; Stage 1's ColourSpriteMirrored at $B46F is the same code.
;
; Witness: L1 281 (rzx-r3).
ColourSpriteMirrored:
  PUSH BC
  CALL AttrShadowAddress
  LD C,(IX+$02)
  LD B,$00
  DEC HL
  ADD HL,BC
  POP BC
  LD DE,$0020
  LD B,(IX+$03)
  SRL B
  SRL B
  SRL B
  INC B
ColourSpriteMirroredRow:
  PUSH BC
  PUSH HL
  LD B,(IX+$02)
ColourSpriteMirroredCell:
  LD (HL),C
  DEC L
  DJNZ ColourSpriteMirroredCell
  POP HL
  ADD HL,DE
  POP BC
  DJNZ ColourSpriteMirroredRow
  RET
