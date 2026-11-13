; --------------------------------------------------------------------------------------------------------------------
; render.asm: The renderer: the sprite row plotters, the play buffer, the attributes, ClearBuffer and CopyBuffer
; --------------------------------------------------------------------------------------------------------------------

  ORG $7929

; Fade every coloured ink up to white over 7 frames, then down to black over 7
; frames
;
; Seven times (HALT each): every attribute whose ink is neither 0 nor 7 gets
; ink + 1. Then seven times (two HALTs each): every ink not 0 gets ink - 1.
; Inputs: none; changes the whole attribute area $5800-$5AFF. Called by
; EndStageSave $7914. As in stage 1 at `$7925`.
;
; Witness: L1 2 (rzx-r4, s4-right).
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

  ORG $79FD

; Copy a block of bytes to the screen, line by line
;
; Inputs: HL = the source, B = the screen column, C = the first pixel line, D =
; the width in bytes, E = the lines, A = the source's stride (added to HL after
; each line; 0 repeats one source line, used with the cleared buffer to clear a
; screen block). Patches the column into the ADD A,n at $7A15 and the stride
; into the LD C,n at $7A26, then for each line takes the line's address from
; ScreenLineTable and LDIRs D bytes. Destroys IX, A, BC, DE. Callers:
; EndStageSave, ShowScore, ShowItemCount, ShowPieceTaken, GameOverStep and the
; score reveal $97E1, $97F1.
;
; Witness: L1 9426 (rzx-r4, s4-right).
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

  ORG $7F89

; For an actor with a shift (+$11 = 1-7): copy its sprite to $7640 and shift it
; right
;
; IY = the actor record. +$11 = 0 or $64 and up: nothing. Else copies the
; sprite (+4/+5, +2 bytes wide, +3 lines) to $7640 with a zero byte added to
; each line, then shifts each line right by +$11 pixels with the routine
; ShiftRoutines[+$11] (patched into PreShiftCall). Called by $A7D0 for every
; actor drawn. As in stage 1 at `$7F4D`.
;
; Witness: L1 67987 (rzx-r4, s4-right).
;
; In s4-right 42 of the calls copied and shifted a sprite (the hero hopping
; back from the barrier, HeroRecoil); in rzx-r4 no actor had a shift.
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
; Read by PreShiftSprite $7FB3: ShiftLine1 to ShiftLine7. Read in s4-right (42
; times).
ShiftRoutines:
  DEFW $0000,ShiftLine1,ShiftLine2,ShiftLine3,ShiftLine4,ShiftLine5,ShiftLine6,ShiftLine7

; Shift one line of (IY+2)+1 bytes at HL one pixel right; HL moves past it
;
; Witness: L1 1656 (s4-right).
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
; Witness: L1 138 (s4-right).
ShiftLine2:
  PUSH HL
  CALL ShiftLine1
  POP HL
  CALL ShiftLine1
  RET

; Three pixels: ShiftLine1 three times
;
; Witness: L1 138 (s4-right).
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
; Witness: L1 552 (s4-right).
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
; Witness: L1 138 (s4-right).
ShiftLine5:
  PUSH HL
  CALL ShiftLine4
  POP HL
  JR ShiftLine1

; Six pixels: ShiftLine4 and ShiftLine1 twice
;
; Witness: L1 138 (s4-right).
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
; Witness: L1 138 (s4-right).
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

  ORG $8D71

; Plot one sprite row 1 byte wide into the play buffer
;
; HL = the sprite's bytes, DE = the buffer address. ORs (HL) into (DE) (no
; mask: the buffer is cleared every pass), then HL + 1 and DE + 32 (the next
; pixel line). One of the row plotters of RowPlotters $8F0B, read by the sprite
; drawer at $A850. The plotters 1-7 bytes wide all work so; the mirrored ones
; write the row right to left through the bit-reversal table at $FA00
; (resident), so a sprite faces left. As in stage 1 at `$8776`.
;
; Witness: L1 67002 (rzx-r4, s4-right).
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
; As PlotRow1, the byte bit-reversed through the table $FA00.
;
; Witness: L1 18883 (rzx-r4).
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
; Witness: L1 88666 (rzx-r4, s4-right).
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
; Witness: L1 29976 (rzx-r4).
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
; Witness: L1 46065 (rzx-r4, s4-right).
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
; Witness: L1 32649 (rzx-r4).
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
; Witness: L1 4631 (rzx-r4).
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
; Not executed in any recording (the recordings checked: rzx-r4, s4-right);
; known only from the code (RowPlotters word 9).
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
; Not executed in any recording (the recordings checked: rzx-r4, s4-right);
; known only from the code (RowPlotters word 10).
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
; Not executed in any recording (the recordings checked: rzx-r4, s4-right);
; known only from the code (RowPlotters word 11).
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
; Not executed in any recording (the recordings checked: rzx-r4, s4-right);
; known only from the code (RowPlotters word 12).
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
; Not executed in any recording (the recordings checked: rzx-r4, s4-right);
; known only from the code (RowPlotters word 13).
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
; The widest plotter; RowPlotters has no mirrored 7-byte entry (word 15 is
; HangFlashBorder).
;
; Not executed in any recording (the recordings checked: rzx-r4, s4-right);
; known only from the code (RowPlotters word 14).
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
; Read by the sprite drawer at $A850 (LD BC,RowPlotters): index 2 x width +
; (facing left). Width 0 and the mirrored width 7 hold HangFlashBorder, never
; reached with a valid frame. Read in both recordings.
RowPlotters:
  DEFW HangFlashBorder,HangFlashBorder,PlotRow1,PlotRow1Mirrored,PlotRow2,PlotRow2Mirrored,PlotRow3,PlotRow3Mirrored
  DEFW PlotRow4,PlotRow4Mirrored,PlotRow5,PlotRow5Mirrored,PlotRow6,PlotRow6Mirrored,PlotRow7,HangFlashBorder

  ORG $902A

; Draw a row-packed picture into a buffer
;
; HL = the picture, DE = the buffer address of its first line, B = its lines.
; Each line is one byte, the bytes to copy in its high nibble and the columns
; to skip in its low nibble, then those bytes; DE + 32 a line. The boss picture
; $C4A5 is in this form (DrawBossPicture $8F45, its only caller).
;
; Witness: L1 47632 (rzx-r4).
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

  ORG $9163

; Fill a rectangle of the screen's attributes (5 bytes after the CALL)
;
; The 5 bytes after the CALL: the column, the pixel line (/8 = the cell row),
; the width, the height in cells, the attribute. Returns after them. Callers:
; StartStageExit (StageExitBox), FlashSelectedBox (SelectedBoxRecord),
; GameOverStep (GameOverBox).
;
; Witness: L1 280 (rzx-r4, s4-right).
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
; As FillAttributes into the shadow; StageSetUp ($973B-$9753) paints the HUD's
; boxes and clears the play area's colours with it.
;
; Witness: L1 8 (rzx-r4, s4-right).
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
; Called by StageSetUp $9726 and $975B.
;
; Witness: L1 4 (rzx-r4, s4-right).
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
; (Cells from $7282) is 0 (open), the attribute comes from the shadow $6DC2
; (the room's colours with the actors' painted in); solid cells keep theirs.
; Then CopyBuffer $9A4D. With RestoreAttributes = 1: clears it, CopyBuffer
; first, then after a HALT every cell is written: open cells from the shadow,
; solid cells from $7042. Called by MainLoop $786A. As stage 1's
; UpdateAttributes `$8CAA`.
;
; Witness: L1 8619 (rzx-r4, s4-right).
UpdateAttributes:
  LD A,(RestoreAttributes)
  CP $01
  JP Z,RestoreAttrs
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
RestoreAttrs:
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
  JP NZ,RestoreAttrStore
  LD C,(HL)
RestoreAttrStore:
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

  ORG $9612

; One step of the colour fade: each cell's ink one nearer its shadow attribute
;
; Over the 18 x 28 attributes from $58C2 (row 6 column 2) against the shadow
; $6DC2: where the shadow is non-zero, on odd passes the ink goes down one, on
; even ones up one toward the shadow's ink (with the shadow's paper).
; StageFadeIn calls it 35 times. As in stage 1 at `$9325`.
;
; Witness: L1 70 (rzx-r4, s4-right).
FadeInStep:
  LD HL,Attributes+194
  LD DE,PlayAttributesCell
  LD B,$12
FadeRow:
  PUSH BC
  LD B,$1C
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
  DJNZ FadeCell
  LD BC,$0004
  ADD HL,BC
  EX DE,HL
  ADD HL,BC
  EX DE,HL
  POP BC
  DJNZ FadeRow
  RET

  ORG $9959

; Turn the cells into tile kinds and list the open runs as spans for CopyBuffer
;
; Patches BuildSpansKinds with the tile kinds' address ($5B0A + the header word
; $5B00). Each cell's tile number becomes its kind (0 open, else solid
; scenery). Each run of open cells in a row becomes a span (AddSpan): 6 bytes
; from $76A0: the length in cells, 0, the play buffer's address, the screen's
; address; each further open cell adds 1 to the length (`INC (IX-6)`).
; SpanCount = the spans. As in stage 1 at `$99E9`.
;
; Witness: L1 57 (rzx-r4, s4-right).
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
; the screen's ($FB60 + SpanRow x 16, i.e. ScreenLineTable from line 48, +
; CellColumn); IX + 6.
;
; Witness: L1 1238 (rzx-r4, s4-right).
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
; Witness: L1 8681 (rzx-r4, s4-right).
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
; DE: the screen). For each span: patches CopyLineEnd's LD BC with 32 - the
; length, writes JP CopyLineEnd into CopyChain at 2 x the length (its address
; kept in CopySpanRestore's LD HL), and CopyLineE's LD E with the screen
; address's low byte; copies 8 lines (LDIs, then HL + 32 - length, E back, D +
; 1); puts ED A0 ED back. SpanCount spans; interrupts off meanwhile. As in
; stage 1 at `$9ADA`.
;
; Witness: L1 8621 (rzx-r4, s4-right).
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
  LD (HL),$B8
  INC HL
  LD (HL),$9A
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

  ORG $A1BA

; Fill the attributes of screen rows 6-23 with 0 (black on black)
;
; Fills $58C0-$5AFF (the play area's 576 attributes) with 0 before a room is
; drawn. Called by RoomChange `$9813`. As in stage 1 at `$A057`.
;
; Witness: L1 57 (rzx-r4, s4-right).
BlackOutPlayArea:
  LD HL,Attributes+192
  LD DE,Attributes+193
  LD BC,$023F
  LD (HL),$00
  LDIR
  RET

  ORG $A768

; Draw every visible actor into the play buffer, in two passes (+$0F bit 7
; last)
;
; First pass: the used records with +$0F bits 6 and 7 clear; second pass: those
; with bit 7 (drawn over the others). Each: ClipActor then DrawActorSprite. Bit
; 6 is never drawn. Called from `$782E` and the main loop `$785E`. As in stage
; 1 at `$A5DF`.
;
; Witness: L1 8621 (rzx-r4, s4-right).
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
; address, HL = the frame. Line $C8 and up (above the top): ClipActorTop. Lines
; $90-$C7 (below the play area): B = 0. Else B = the height cut at line $90;
; PreShiftSprite $7F89 makes the shifted copy at $7640 when +$11 is 1-99, and
; HL is then $7640, else the frame +4/+5. As in stage 1 at `$A62A`.
;
; Witness: L1 68207 (rzx-r4, s4-right).
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

; DE = $5B00 + line x 32 + column of the actor IY
;
; Called by ClipActor `$A7D3`; ClipActorTop, after its RET, is ClipActor's
; branch for an actor above the top. As in stage 1 at `$A664`.
;
; Witness: L1 67987 (rzx-r4, s4-right).
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
; routine from the table $8F0B (4 bytes a width: the right-facing and the
; left-facing routine); the left-facing ones mirror the bytes through the
; resident bit-reverse table $FA00. A shifted copy (+$11 1-99) is one byte
; wider. The routine is written into RowDrawCall. Then ColourActor. As in stage
; 1 at `$A6AA`.
;
; Witness: L1 68207 (rzx-r4, s4-right).
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
; The cells under the actor (screen row line / 8 + 6; the column, or column -
; width + 1 facing left; the width +2, + 1 when shifted, written into
; ColourWidth; the rows the lines cover, cut at line $90) get +$0C in the
; attribute shadow at $6D00. Nothing below the play area. As in stage 1 at
; `$A6FF`.
;
; Witness: L1 68207 (rzx-r4, s4-right).
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

; Free the actor when it is in the hero's column and cell row (not referenced)
;
; When the hero's column ($74E0) equals +0 and the hero's line and +1 are in
; the same cell row: +0 = $FF and a jump to ReturnZ $B4A2. No instruction or
; word of the image refers to `$A90F`. As in stage 1 at `$A79D`.
;
; Not executed in any recording (the recordings checked: s4-right, rzx-r4);
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

  ORG $B380

; Copy the screen's attributes to the shadow at $6D00
;
; Called by StageSetUp `$9788`. As in stage 1 at `$B17F`.
;
; Witness: L1 2 (rzx-r4, s4-right).
SaveAttributes:
  LD HL,Attributes
  LD DE,ShadowAttributes
  LD BC,$0300
  LDIR
  RET

; Show the room's cells as colours: each cell x 8 as the attribute of its
; screen cell (not referenced)
;
; The 18 x 28 cells from $7282 into the attributes from $58C2: the cell's bits
; x 8: bit 0 blue paper, bit 1 (solid) red paper, bit 2 green paper, bit 3
; (deadly) BRIGHT. No instruction or word of the image refers to `$B38C`.
;
; Not executed in any recording (the recordings checked: s4-right, rzx-r4);
; known only from the code.
CellsToAttributes:
  LD HL,Attributes+194
  LD DE,CellsPlay
  LD B,$12
CellsToAttributesRow:
  PUSH BC
  LD B,$1C
CellsToAttributesCell:
  LD A,(DE)
  SLA A
  SLA A
  SLA A
  LD (HL),A
  INC DE
  INC HL
  DJNZ CellsToAttributesCell
  LD BC,$0004
  ADD HL,BC
  EX DE,HL
  ADD HL,BC
  EX DE,HL
  POP BC
  DJNZ CellsToAttributesRow
  RET

  ORG $B4F4

; HL = the play-buffer address of the actor IY ($5B00 + line x 32 + column); DE
; = HL in
;
; As in stage 1 at `$B332`.
;
; Witness: L1 5575 (rzx-r4, s4-right).
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
; The shadow's row 6 ($6DC0) is the play area's top row. As in stage 1 at
; `$B349`.
;
; Witness: L1 5575 (rzx-r4, s4-right).
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

  ORG $B61D

; Draw the image IX points to, mirrored, and colour it
;
; HL = the image (IX +0/+1), DrawSpriteMirrored, MissileColour,
; ColourSpriteMirrored. No instruction or word of the image refers to `$B61D`.
; As in stage 1 at `$B3DA`.
;
; Not executed in any recording (the recordings checked: s4-right, rzx-r4);
; known only from the code.
DrawMissileMirrored:
  LD L,(IX+$00)
  LD H,(IX+$01)
  CALL DrawSpriteMirrored
  CALL MissileColour
  CALL ColourSpriteMirrored
  RET

; Nine image descriptors: the image address, the width in bytes, the height in
; lines
;
; $E4C3, $E4EA, $E511, $E538 (3 x 13) and $E55F, $E577, $E58F, $E5A7, $E5BF (3
; x 8). Only the first two are read: IX = `$B62D` or `$B631` by the bit 0 of
; the missile's +5 (`$8509`, `$8514`, kinds 5 and 6, the thrown item); the
; other seven have no reader.
ImageDescriptors:
  DEFB $C3,$E4,$03,$0D
  DEFB $EA,$E4,$03,$0D
  DEFB $11,$E5,$03,$0D
  DEFB $38,$E5,$03,$0D
  DEFB $5F,$E5,$03,$08
  DEFB $77,$E5,$03,$08
  DEFB $8F,$E5,$03,$08
  DEFB $A7,$E5,$03,$08
  DEFB $BF,$E5,$03,$08

; Four rows of 16 rising steps 1-5: no reader found (known only from the code)
;
; No instruction or word of the image refers to `$B651`; it takes the place of
; stage 1's SpeedSteps (`$B3FA`).
SpeedRamps:
  DEFB $01,$01,$01,$01,$01,$01,$02,$02,$02,$02,$03,$03,$03,$03,$03,$04
  DEFB $01,$01,$01,$01,$02,$02,$02,$02,$02,$02,$03,$03,$03,$03,$04,$04
  DEFB $01,$01,$01,$01,$01,$02,$02,$02,$02,$02,$03,$03,$03,$04,$04,$05
  DEFB $01,$01,$01,$01,$01,$01,$01,$01,$02,$02,$02,$02,$02,$02,$03,$03

; Fill the attribute shadow under an image with C
;
; IY = the position, IX the image descriptor (+2 width, +3 height): (height / 8
; + 1) rows of the width. As in stage 1 at `$B40A`.
;
; Witness: L1 5431 (rzx-r4, s4-right).
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
; the position (BufferAddressHL). The bytes replace the buffer's. As in stage 1
; at `$B42B`.
;
; Witness: L1 2740 (rzx-r4).
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
; As DrawSprite, each row written from right to left and each byte reversed by
; the resident's table at $FA00. As in stage 1 at `$B446`.
;
; Witness: L1 80 (rzx-r4).
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

; ColourSprite for a mirrored image (filled leftwards from its right edge)
;
; As in stage 1 at `$B46F`.
;
; Witness: L1 80 (rzx-r4).
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
