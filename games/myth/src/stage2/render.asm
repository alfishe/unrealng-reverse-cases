; --------------------------------------------------------------------------------------------------------------------
; render.asm: The renderer: the sprite row plotters, the play buffer, the attributes, ClearBuffer and CopyBuffer
; --------------------------------------------------------------------------------------------------------------------

  ORG $792E

; Fade every coloured ink up to white over 7 frames, then down to black over 7
; frames
;
; Seven times (HALT each): every attribute whose ink is neither 0 nor 7 gets
; ink + 1. Then seven times (two HALTs each): every ink not 0 gets ink - 1.
; Inputs: none; changes the whole attribute area $5800-$5AFF. Called by
; EndStage.
;
; As in stage 1 at $7925, the same code.
;
; Witness: L1 2 (rzx-r2, s2-right).
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

  ORG $7982

; Copy a block of bytes to the screen, line by line
;
; Inputs: HL = the source, B = the screen column, C = the first pixel line, D =
; the width in bytes, E = the lines, A = the source's stride (added to HL after
; each line; 0 repeats one source line, used with the cleared buffer to clear a
; screen block). Patches the column into $799B and the stride into $79AC, then
; for each line takes the line's address from ScreenLineTable and LDIRs D
; bytes. Destroys IX, BC, DE.
;
; As in stage 1 at $79CC, the same code.
;
; Witness: L1 8701 (rzx-r2, s2-right, stageload).
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

  ORG $7F10

; For an actor with a shift (+$11 = 1-7): copy its sprite to $7640 and shift it
; right
;
; IY = the actor record. +$11 = 0 or $64 and up: nothing. Else copies the
; sprite (+4/+5, +2 bytes wide, +3 lines) to $7640 with a zero byte added to
; each line, then shifts each line right by +$11 pixels with the routine
; ShiftRoutines[+$11] (patched into PreShiftCall). Called by ClipActor $A590
; for every actor drawn.
;
; As in stage 1 at $7F4D, the same code.
;
; Witness: L1 40014 (rzx-r2, s2-right, stageload).
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
; 0, ShiftLine1, ShiftLine2, ShiftLine3, ShiftLine4, ShiftLine5, ShiftLine6,
; ShiftLine7. Read by PreShiftSprite ($7F3A), which patches the CALL at
; PreShiftCall with entry +$11 of the actor.
ShiftRoutines:
  DEFW $0000,ShiftLine1,ShiftLine2,ShiftLine3,ShiftLine4,ShiftLine5,ShiftLine6,ShiftLine7

; Shift one line of (IY+2)+1 bytes at HL one pixel right; HL moves past it
;
; Called by ShiftLine2 ($7F70), ShiftLine2 ($7F74), ShiftLine3 ($7F79),
; ShiftLine3 ($7F7E), ShiftLine3 ($7F82), ShiftLine6 ($7F9E), ShiftLine7
; ($7FAA), ShiftLine7 ($7FAF); jumped to from ShiftLine5 ($7F96), ShiftLine6
; ($7FA2), ShiftLine7 ($7FB3).
;
; As in stage 1 at $7FA0, the same code.
;
; Witness: L1 26595 (rzx-r2).
ShiftLine1:
  LD B,(IY+$02)
  SRL (HL)
  INC L
ShiftLine1Byte:
  RR (HL)
  INC L
  DJNZ ShiftLine1Byte
  RET

; Two pixels: ShiftLine1 twice over the same line
;
; HL = the line; IY = the actor (+2 the width). One of ShiftRoutines (entry 2),
; called by PreShiftSprite ($7F4C). rzx-r2 runs it 3970 times (frames
; 8348-14306: Medusa's and the hydra's rooms).
;
; As in stage 1 at $7FAC.
;
; Witness: L1 3970 (rzx-r2).
ShiftLine2:
  PUSH HL
  CALL ShiftLine1
  POP HL
  CALL ShiftLine1
  RET

; Three pixels: ShiftLine1 three times
;
; As ShiftLine2, ShiftRoutines entry 3. rzx-r2: 293 times (frames 8363-11090).
;
; As in stage 1 at $7FB3.
;
; Witness: L1 293 (rzx-r2).
ShiftLine3:
  PUSH HL
  CALL ShiftLine1
  POP HL
  PUSH HL
  CALL ShiftLine1
  POP HL
  CALL ShiftLine1
  RET

; Four pixels: RLD along the line
;
; Called by ShiftLine5 ($7F92), ShiftLine6 ($7F99), ShiftLine7 ($7FA5).
;
; As in stage 1 at $7FBF, the same code.
;
; Witness: L1 10605 (rzx-r2).
ShiftLine4:
  LD B,(IY+$02)
  INC B
  XOR A
ShiftLine4Byte:
  RRD
  INC L
  DJNZ ShiftLine4Byte
  RET

; Five pixels: ShiftLine4 and ShiftLine1
;
; ShiftRoutines entry 5; the two operands are ShiftLine4 and ShiftLine1 (JR).
; rzx-r2: 2114 times (frames 8345-14179).
;
; As in stage 1 at $7FCA.
;
; Witness: L1 2114 (rzx-r2).
ShiftLine5:
  PUSH HL
  CALL ShiftLine4
  POP HL
  JR ShiftLine1

; Six pixels: ShiftLine4 and ShiftLine1 twice
;
; ShiftRoutines entry 6. rzx-r2: 2735 times (frames 8360-14314).
;
; As in stage 1 at $7FD1.
;
; Witness: L1 2735 (rzx-r2).
ShiftLine6:
  PUSH HL
  CALL ShiftLine4
  POP HL
  PUSH HL
  CALL ShiftLine1
  POP HL
  JR ShiftLine1

; Seven pixels: ShiftLine4 and ShiftLine1 three times
;
; ShiftRoutines entry 7. rzx-r2: 2449 times (frames 8351-14187).
;
; As in stage 1 at $7FDD.
;
; Witness: L1 2449 (rzx-r2).
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
  JR ShiftLine1

  ORG $88BF

; Plot one sprite row 1 byte wide into the play buffer
;
; HL = the sprite's bytes, DE = the buffer address. ORs (HL) into (DE) (no
; mask: the buffer is cleared every pass),
;
; then HL + 1 and DE + 32 (the next pixel line). One of the row plotters of
; RowPlotters $8A59, called once a row by
;
; the sprite drawer at DrawActorSprite $A60E. The plotters 1-7 bytes wide all
; work so; the mirrored ones read the row's bytes in
;
; order and write them right to left through the bit-reversal table at $FA00
; (resident), so a sprite faces left.
;
; As in stage 1 at $8776, the same code.
;
; Witness: L1 61507 (rzx-r2, s2-right, stageload).
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
; As in stage 1 at $8781, the same code.
;
; Witness: L1 13560 (rzx-r2).
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
; As in stage 1 at $8793, the same code.
;
; Witness: L1 89117 (rzx-r2, s2-right, stageload).
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
; As in stage 1 at $87A3, the same code.
;
; Witness: L1 14434 (rzx-r2).
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
; Called through DrawActorSprite's patched CALL ($A642, RowDrawCall) for each
; line of a frame 3 bytes wide.
;
; As in stage 1 at $87BD, the same code.
;
; Witness: L1 86725 (rzx-r2, s2-right, stageload).
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
; Called through DrawActorSprite's patched CALL ($A642, RowDrawCall) for each
; line of a frame 3 bytes wide mirrored.
;
; As in stage 1 at $87D2, the same code.
;
; Witness: L1 29125 (rzx-r2).
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
; Called through DrawActorSprite's patched CALL ($A642, RowDrawCall) for each
; line of a frame 4 bytes wide.
;
; As in stage 1 at $87F4, the same code.
;
; Witness: L1 46495 (rzx-r2, s2-right).
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
; Called through DrawActorSprite's patched CALL ($A642, RowDrawCall) for each
; line of a frame 4 bytes wide mirrored.
;
; As in stage 1 at $880E, the same code.
;
; Witness: L1 528 (rzx-r2).
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
; As in stage 1 at $8838, the same code.
;
; Witness: L1 1260 (rzx-r2, s2-right).
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
; Called through DrawActorSprite's patched CALL ($A642, RowDrawCall) for each
; line of a frame 5 bytes wide mirrored.
;
; As in stage 1 at $8857, the same code.
;
; Witness: L1 252 (rzx-r2).
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
; Used by the 6-byte frames (in stage 2 the harpy's wings at $D797, frame 1).
;
; As in stage 1 at $8889, the same code.
;
; Witness: L1 6221 (rzx-r2, s2-right).
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
; As in stage 1 at $88AD, the same code.
;
; Not executed in any recording (the recordings checked: s2-right, rzx-r2);
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
; $88B6).
;
; As in stage 1 at $88E7, the same code.
;
; Not executed in any recording (the recordings checked: s2-right, rzx-r2);
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
; Read by the sprite drawer at $A62D (LD BC,RowPlotters): index 2 x width +
; (facing left). Width 0 and the mirrored width 7 hold HangFlashBorder $88B6 (a
; hang loop: border flicker and KeyHook forever), never reached with a valid
; frame.
RowPlotters:
  DEFW HangFlashBorder,HangFlashBorder,PlotRow1,PlotRow1Mirrored,PlotRow2,PlotRow2Mirrored,PlotRow3,PlotRow3Mirrored
  DEFW PlotRow4,PlotRow4Mirrored,PlotRow5,PlotRow5Mirrored,PlotRow6,PlotRow6Mirrored,PlotRow7,HangFlashBorder

  ORG $8B2A

; Draw a row-packed picture into a buffer
;
; HL = the picture, DE = the buffer address of its first line, B = its lines.
; Each line is one byte, the bytes to
;
; copy in its high nibble and the columns to skip in its low nibble, then those
; bytes; DE + 32 a line. The room and
;
; arena pictures are in this form; in stage 2 the hydra's body HydraBodyPicture
; $D967.
;
; As in stage 1 at $8B03, the same code.
;
; Witness: L1 46384 (rzx-r2).
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

  ORG $8C63

; Fill a rectangle of the screen's attributes (5 bytes after the CALL)
;
; The 5 bytes after the CALL: the column, the pixel line (/8 = the cell row),
; the width, the height in cells, the
;
; attribute. Returns after them. Called by StartStageExit ($7AAF),
; FlashSelectedBoxFrame ($7C43) and GameOverStep ($8599).
;
; As in stage 1 at $8C3D, the same code.
;
; Witness: L1 274 (rzx-r2, s2-right, stageload).
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
; As in stage 1 at $8C6D, the same code.
;
; Witness: L1 355 (rzx-r2, s2-right, stageload).
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
; Called by StageSetUp ($9188), StageSetUp ($91BD).
;
; As in stage 1 at $8C9D, the same code.
;
; Witness: L1 6 (rzx-r2, s2-right, stageload).
ShowShadowAttributes:
  LD HL,ShadowAttributes
  LD DE,Attributes
  LD BC,$0300
  HALT
  LDIR
  RET

; Copy the open cells' attributes from the shadow, then CopyBuffer
;
; The play area's 18 rows x 28 columns from row 6 column 2: where the cell kind
; ($7282, BuildSpans) is 0 (open), the attribute comes from the shadow $6DC2
; (the room's colours with the actors' painted in); solid cells keep theirs.
; Then CopyBuffer. With RestoreAttributes = 1 (set by SavePlayAttrs): clears
; it, CopyBuffer first, then after a HALT every cell is written: open cells
; from the shadow, solid cells from RoomAttributes $7042. Every pass (MainLoop
; $786A); the restore ran 32 times in rzx-r2 (the room changes).
;
; As in stage 1 at $8CAA.
;
; Witness: L1 8031 (rzx-r2, s2-right, stageload).
UpdateAttributes:
  LD A,(RestoreAttributes)
  CP $01
  JP Z,UpdateAttrRestore
  LD DE,Attributes+194
  LD HL,PlayAttributesCell
  LD IX,CellsPlay
  LD B,$12
UpdateAttrRow:
  PUSH BC
  LD B,$1C
UpdateAttrCell:
  LD A,(IX+$00)
  CP $00
  JR NZ,UpdateAttrNext
  LD A,(HL)
  LD (DE),A
UpdateAttrNext:
  INC DE
  INC HL
  INC IX
  DJNZ UpdateAttrCell
  LD BC,$0004
  ADD HL,BC
  EX DE,HL
  ADD HL,BC
  EX DE,HL
  ADD IX,BC
  POP BC
  DJNZ UpdateAttrRow
  CALL CopyBuffer
  RET
UpdateAttrRestore:
  LD A,$00
  LD (RestoreAttributes),A
  CALL CopyBuffer
  LD IX,Attributes+194
  LD HL,PlayAttributesCell
  LD IY,RoomAttributesCell
  LD DE,CellsPlay
  LD B,$12
  HALT
RestoreAttrRow:
  PUSH BC
  LD B,$1C
RestoreAttrCell:
  LD C,(IY+$00)
  LD A,(DE)
  OR A
  JP NZ,RestoreAttrPut
  LD C,(HL)
RestoreAttrPut:
  LD (IX+$00),C
  INC E
  INC IYL
  INC L
  INC IXL
  DJNZ RestoreAttrCell
  LD BC,$0004
  ADD HL,BC
  ADD IY,BC
  ADD IX,BC
  EX DE,HL
  ADD HL,BC
  EX DE,HL
  POP BC
  DJNZ RestoreAttrRow
  RET

  ORG $9149

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
; As in stage 1 at $9325, the same code.
;
; Witness: L1 105 (rzx-r2, s2-right, stageload).
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

  ORG $93B5

; Turn the cells into tile kinds and list the open runs as spans for CopyBuffer
;
; Patches BuildSpansKinds with the tile kinds' address ($5B0A + the header word
; $5B00). Each cell's tile number becomes its kind (0 open, else solid
; scenery). Each run of open cells in a row becomes a span (AddSpan): 6 bytes
; from $76A0: the length in cells, 0, the play buffer's address, the screen's
; address. SpanCount = the spans. Called by RoomChange ($92E2) at every room
; change: 33 times in rzx-r2.
;
; As in stage 1 at $99E9.
;
; Witness: L1 43 (rzx-r2, s2-right, stageload).
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
  LD A,$00
  LD (SpanRow),A
  LD IY,CellsPlay
  LD IX,SpanTable
  LD B,$12
BuildSpansRow:
  PUSH BC
  LD B,$1C
  LD A,$00
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
  LD A,$00
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
; As in stage 1 at $9A6E, the same code.
;
; Witness: L1 1374 (rzx-r2, s2-right, stageload).
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
; As in stage 1 at $9AB5, the same code.
;
; Witness: L1 8080 (rzx-r2, s2-right, stageload).
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
; DE: the screen). For each span: patches the LD BC at CopyLineEnd with 32 -
; the length, writes JP CopyLineEnd ($C3 $14 $95 at $94C8-$94CE) into the LDI
; chain at CopyChain + 2 x the length (the place saved at CopySpanRestore), the
; LD E at CopyLineE with the screen address's low byte; copies 8 lines (LDIs,
; then HL + 32 - length, E back, D + 1); puts ED A0 ED back. SpanCount spans;
; interrupts off meanwhile. Called by UpdateAttributes every pass and by
; StageEntry.
;
; As in stage 1 at $9ADA, the same code; the operands at $94BC-$94D3 are its
; own labels and the bytes $14 $95 the low and high bytes of CopyLineEnd.
;
; Witness: L1 8033 (rzx-r2, s2-right, stageload).
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
  LD (HL),$14
  INC HL
  LD (HL),$95
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

  ORG $99D3

; Fill the attributes of screen rows 6-23 with 0 (black on black)
;
; Fills $58C0-$5AFF (the play area's 576 attributes) with 0 before a room is
; built. Called by the room builder $9257.
;
; As in stage 1 at $A057, the same code.
;
; Witness: L1 43 (rzx-r2, s2-right, stageload).
BlackOutPlayArea:
  LD HL,Attributes+192
  LD DE,Attributes+193
  LD BC,$023F
  LD (HL),$00
  LDIR
  RET

  ORG $A545

; Draw every visible actor into the play buffer, in two passes (+$0F bit 7
; last)
;
; First pass: the used records with +$0F bits 6 and 7 clear; second pass: those
; with bit 7 (drawn over the others). Each: ClipActor $A590 then
; DrawActorSprite $A60E. Bit 6 is never drawn. Called twice a main-loop pass
; ($782E, $785B).
;
; As in stage 1 at $A5DF, the same code.
;
; Witness: L1 8034 (rzx-r2, s2-right, stageload).
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
; PreShiftSprite $7F10 makes the shifted copy at $7640 when +$11 is 1-99, and
; HL is then $7640, else the frame +4/+5.
;
; As in stage 1 at $A62A, the same instructions (two JP turned into JR).
;
; Witness: L1 40129 (rzx-r2, s2-right, stageload).
ClipActor:
  LD A,(IY+$01)
  CP $C8
  JR NC,ClipActorTop
  CP $90
  JR NC,ClipActorOff
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
; Called by ClipActor $A5B0. ClipActorTop $A5DE and ClipActorOff $A60B are
; ClipActor's exits that follow it in memory.
;
; As in stage 1 at $A664, the same code.
;
; Witness: L1 40014 (rzx-r2, s2-right, stageload).
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
; This entry point is used by the routine at ClipActor.
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
; routine from the table $8A59 (4 bytes a width 0-7: the right-facing and the
; left-facing routine); the left-facing routines mirror the bytes through the
; resident BitReverse $FA00 and step left, so a left-facing actor's X is its
; right column. A shifted copy (+$11 1-99) is one byte wider. The routine is
; written into RowDrawCall. Then ColourActor $A662.
;
; As in stage 1 at $A6AA, the same instructions (one JP turned into JR).
;
; Witness: L1 40129 (rzx-r2, s2-right, stageload).
DrawActorSprite:
  LD A,B
  CP $00
  RET Z
  BIT 0,(IY+$09)
  JR NZ,DrawActorOpaque
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
; Nothing below the play area. Called by DrawActorSprite ($A647, $A65E).
;
; As in stage 1 at $A6FF, the same instructions (one JR turned into JP).
;
; Witness: L1 40065 (rzx-r2, s2-right, stageload).
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
  JP Z,ColourActorRows2
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

  ORG $A8EB

; +$0C = ItemInks[+$0B & 3]
;
; In stage 1 no code referred to it; in stage 2 the flying harpy ($8E06, 351
; calls in s2-right, 367 in rzx-r2) and
;
; HarpyRiseActor's wake ($A84A) call it: their colours cycle red, magenta,
; blue, white.
;
; As in stage 1 at $A788, the same code.
;
; Witness: L1 764 (rzx-r2, s2-right).
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
; Read by CycleItemInk $A8F6: $42, $43, $41, $47. As in stage 1 at $A799.
ItemInks:
  DEFB $41,$42,$43,$42

; Free the actor when it is in the hero's column and cell row (not referenced)
;
; When the hero's X ($74E0) equals +0 and the hero's Y and +1 are in the same
; cell row: +0 = $FF and a jump to ReturnZ $B40B. No code or table in the image
; refers to $A900.
;
; Not executed in any recording (the recordings checked: s2-right, rzx-r2);
; known only from the code.
;
; As in stage 1 at $A79D, the same code.
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

  ORG $B2F9

; Copy the screen's attributes to the shadow at $6D00
;
; Called once from $91EA.
;
; As in stage 1 at $B17F, the same code.
;
; Witness: L1 3 (rzx-r2, s2-right, stageload).
SaveAttributes:
  LD HL,Attributes
  LD DE,ShadowAttributes
  LD BC,$0300
  LDIR
  RET
