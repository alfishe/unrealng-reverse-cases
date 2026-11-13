; --------------------------------------------------------------------------------------------------------------------
; print.asm: Text and screen: the proportional print, the reveal, the attribute boxes, the colour cycle, the screen clear, the dissolve masks
;
; Print takes its text after the CALL: a column byte, a bit within it, a pixel row, then capital letters, digits and
; spaces up to a 0. TextToBuffer draws the line into TextBuffer with PrintFont (each glyph its own width), then
; RevealText brings it onto the screen in 8 frames through the dissolve masks, while CycleColours runs. AttrBox fills
; an attribute rectangle given after its CALL. ClearScreen clears the screen and paints the colour bands of the title
; screens.
; --------------------------------------------------------------------------------------------------------------------

  ORG $F356

; One frame: FrameCounter + 1, the next colour of ColourCycle into the box
; under the titles
;
; Called every frame by the waits (c1, every recording with a title screen).
; Witness: L1 7883 (c1, ending, joystick, menu, s1-idle, s1-right, s2-right,
; s3-right, s4-right, s5-right, stageload, rzx-r0-rzx-r5).
CycleColours:
  HALT
  LD A,(FrameCounter)
  INC A
  LD (FrameCounter),A
  AND $07
  LD C,A
  LD B,$00
  LD HL,ColourCycle
  ADD HL,BC
  LD A,(HL)
  LD (CycleBoxAttr),A
  CALL AttrBox            ; AttrBox: the cycling box

; AttrBox data: column 6, row 4, 20 wide, 4 high, the attribute written by
; CycleColours
CycleBox:
  DEFB $06,$04,$14,$04
CycleBoxAttr:
  DEFB $00                ; the attribute

; RET
CycleColoursEnd:
  RET

; The box's colours, one a frame: bright red, magenta, green, cyan, yellow and
; back
;
; Read by CycleColours (c1).
ColourCycle:
  INCBIN "res/resident/colour-cycle.bin",$0000,8

; Fill an attribute box: column, row, width, height, attribute after the CALL
;
; The five bytes after the CALL: column, row, width, height, attribute; returns
; after them. Witness: L1 9085 (c1, ending, joystick, menu, s1-idle, s1-right,
; s2-right, s3-right, s4-right, s5-right, stageload, rzx-r0-rzx-r5).
AttrBox:
  POP IY
  LD L,(IY+$01)
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD A,L
  ADD A,(IY+$00)
  LD L,A
  LD BC,Attributes
  ADD HL,BC
  LD B,(IY+$03)
AttrBoxRow:
  PUSH BC
  PUSH HL
  LD B,(IY+$02)
  LD A,(IY+$04)
AttrBoxCell:
  LD (HL),A
  INC L
  DJNZ AttrBoxCell
  POP HL
  LD BC,$0020
  ADD HL,BC
  POP BC
  DJNZ AttrBoxRow
  LD BC,$0005
  ADD IY,BC
  PUSH IY
  RET

; Print the text after the CALL: TextToBuffer, then RevealText at its row
;
; The data: column byte, bit, pixel row, text, 0; returns after the 0. Witness:
; L1 43 (c1, joystick, menu, s1-right, s2-right, s3-right, s4-right, stageload,
; rzx-r0-rzx-r4).
Print:
  POP IY
  CALL TextToBuffer
  PUSH IY
  LD A,(TextRow)
  JP RevealText

; Print the text at IY (a StageTable title), IY past it
;
; Witness: L1 11 (c1, joystick, menu, rzx-r0, rzx-r1, rzx-r3).
PrintRecord:
  CALL TextToBuffer
  LD A,(TextRow)
  PUSH IY
  CALL RevealText
  POP IY
  RET

; Draw the text at IY (column byte, bit, row, text, 0) into TextBuffer with
; PrintFont
;
; Clears TextBuffer, sets BitShift and TextRow; for each character: A-Z, a
; space (as the glyph after Z) and 0-9 (after the space); the glyph's width
; mask to CharMask, its 7 rows to GlyphBuffer, shifted right by BitShift, ORed
; into TextBuffer at DE; then Advance. Ends after the 0 with IY past it.
; Witness: L1 54 (c1, joystick, menu, s1-right, s2-right, s3-right, s4-right,
; stageload, rzx-r0-rzx-r4).
TextToBuffer:
  LD HL,TextBuffer
  LD DE,TextBuffer+1
  LD BC,$0100
  LD (HL),$00
  LDIR
  XOR A
  LD (BitShift),A
  LD D,$5B
  LD E,(IY+$00)
  LD A,(IY+$01)
  LD (BitShift),A
  LD A,(IY+$02)
  LD (TextRow),A
  INC IY
  INC IY
  INC IY
TextNextChar:
  LD A,(IY+$00)
  INC IY
  CP $00
  JP Z,TextEnd
  CP $3A
  JR NC,TextNotDigit
  CP $30
  JR C,TextNotDigit
  ADD A,$2C
  JR TextGlyph
TextNotDigit:
  CP $20
  JR NZ,TextGlyph
  LD A,$5B
TextGlyph:
  SUB $41
  SLA A
  SLA A
  LD C,A
  LD B,$00
  LD HL,PrintFont
  ADD HL,BC
  ADD HL,BC
  LD A,(HL)
  LD (CharMask),A
  INC HL
  PUSH DE
  LD DE,GlyphBuffer
  LD B,$07
TextGlyphRow:
  LD A,(HL)
  LD (DE),A
  INC HL
  INC E
  XOR A
  LD (DE),A
  INC E
  DJNZ TextGlyphRow
  POP DE
  PUSH DE
  LD A,(BitShift)
  CP $00
  JR Z,TextMerge
  LD C,A
TextShift:
  LD HL,GlyphBuffer
  LD B,$07
TextShiftRow:
  SRL (HL)
  INC L
  RR (HL)
  INC L
  DJNZ TextShiftRow
  DEC C
  JR NZ,TextShift
TextMerge:
  LD HL,GlyphBuffer
  LD B,$07
TextMergeRow:
  LD A,(DE)
  OR (HL)
  LD (DE),A
  INC L
  INC E
  LD A,(DE)
  OR (HL)
  LD (DE),A
  INC L
  LD A,E
  ADD A,$1F
  LD E,A
  DJNZ TextMergeRow
  POP DE
  CALL Advance
  JR TextNextChar

; Move BitShift and DE on by the glyph's width: 9 less the trailing zeros of
; CharMask
;
; Witness: L1 760 (c1, joystick, menu, s1-right, s2-right, s3-right, s4-right,
; stageload, rzx-r0-rzx-r4).
Advance:
  LD A,(CharMask)
  LD C,$09
AdvanceCount:
  BIT 0,A
  JR NZ,AdvanceAdd
  SRL A
  DEC C
  JR AdvanceCount
AdvanceAdd:
  LD A,(BitShift)
  ADD A,C
  CP $08
  JR C,AdvanceStore
  INC DE
  SUB $08
AdvanceStore:
  LD (BitShift),A
  RET
; This entry point is used by the routine at TextToBuffer.
TextEnd:
  RET

; Bring TextBuffer onto the screen from pixel row A in 8 frames through the
; dissolve masks
;
; For step 0-7: the ADD A,n at RevealMaskAdd := $CB + step; HALT, CycleColours;
; for the 7 rows and 32 bytes: mask = DissolveMasks set (a ROM byte from $0001
; up AND $18) at the step; screen := (screen AND NOT mask) OR (buffer AND
; mask). Witness: L1 54 (c1, joystick, menu, s1-right, s2-right, s3-right,
; s4-right, stageload, rzx-r0-rzx-r4).
RevealText:
  LD L,A
  LD H,$00
  ADD HL,HL
  LD BC,ScreenLineTable
  ADD HL,BC
  LD (RowPointer),HL
  LD B,$08
RevealStep:
  PUSH BC
  LD A,$08
  SUB B
  ADD A,$CB
  LD (RevealMaskAdd+$0001),A
  HALT
  CALL CycleColours
  LD IY,(RowPointer)
  LD DE,TextBuffer
  LD BC,$0000
  LD (BitShift),BC
  LD B,$07
RevealRow:
  PUSH BC
  LD L,(IY+$00)
  LD H,(IY+$01)
  INC IY
  INC IY
  LD B,$20
RevealByte:
  PUSH BC
  LD BC,(BitShift)
  INC BC
  LD (BitShift),BC
  LD A,(BC)
  AND $18
RevealMaskAdd:
  ADD A,$00               ; ADD A,n: n = $CB + step, written above
  LD C,A
  LD B,$F9
  LD A,(BC)
  LD B,A
  LD A,(DE)
  AND B
  LD C,A
  LD A,B
  XOR $FF
  LD B,A
  LD A,(HL)
  AND B
  OR C
  LD (HL),A
  INC DE
  INC HL
  POP BC
  DJNZ RevealByte
  POP BC
  DJNZ RevealRow
  POP BC
  DJNZ RevealStep
  RET

; Wait BC frames (HALT each)
;
; Witness: L1 0 ().
WaitBC:
  HALT
  DEC BC
  LD A,B
  OR C
  JR NZ,WaitBC
  RET

; Black attributes, a clear bitmap, then the colour bands of rows 18-22 and
; SetMenuBands
;
; Witness: L1 28 (c1, ending, joystick, menu, s1-idle, s1-right, s2-right,
; s3-right, s4-right, s5-right, stageload, rzx-r0-rzx-r5).
ClearScreen:
  CALL AttrBox

; AttrBox data: the whole screen, attribute 0
ClearBox:
  DEFB $00,$00,$20,$18,$00

; the bitmap
ClearScreen2:
  LD HL,Screen
  LD DE,Screen+1
  LD BC,$17FF
  LD (HL),$00
  LDIR
  CALL AttrBox

; AttrBox data: row 18, attribute $42
BandRow18:
  DEFB $00,$12,$20,$01,$42

; ClearScreen3
ClearScreen3:
  CALL AttrBox

; AttrBox data: row 19, attribute $03
BandRow19:
  DEFB $00,$13,$20,$01,$03

; ClearScreen4
ClearScreen4:
  CALL AttrBox

; AttrBox data: row 21, attribute $42
BandRow21:
  DEFB $00,$15,$20,$01,$42

; ClearScreen5
ClearScreen5:
  CALL AttrBox

; AttrBox data: row 22, attribute $03
BandRow22:
  DEFB $00,$16,$20,$01,$03

; The colour bands of rows 10-15 (the titles' rows)
;
; Also called by GameOver for each highlight move. Witness: L1 217 (c1, ending,
; joystick, menu, s1-idle, s1-right, s2-right, s3-right, s4-right, s5-right,
; stageload, rzx-r0-rzx-r5).
SetMenuBands:
  CALL AttrBox

; AttrBox data: rows 10-17, attribute $44
BandRows10:
  DEFB $00,$0A,$20,$08,$44

; SetMenuBands2
SetMenuBands2:
  CALL AttrBox

; AttrBox data: row 11, attribute $05
BandRow11:
  DEFB $00,$0B,$20,$01,$05

; SetMenuBands3
SetMenuBands3:
  CALL AttrBox

; AttrBox data: row 13, attribute $05
BandRow13:
  DEFB $00,$0D,$20,$01,$05

; SetMenuBands4
SetMenuBands4:
  CALL AttrBox

; AttrBox data: row 15, attribute $05
BandRow15:
  DEFB $00,$0F,$20,$01,$05

; SetMenuBandsEnd
SetMenuBandsEnd:
  RET

; 75 frames of CycleColours
;
; Witness: L1 15 (c1, ending, joystick, menu, s5-right, stageload,
; rzx-r0-rzx-r5).
WaitFrames:
  LD B,$4B
WaitFramesLoop:
  HALT
  PUSH BC
  CALL CycleColours
  POP BC
  DJNZ WaitFramesLoop
  RET

  ORG $F646

; Copy B rows of D bytes from HL to the screen at row C, column A (via
; ScreenLineTable)
;
; Not executed in any recording (all checked), no reference from the front or a
; stage (xref.txt). Known only from the code ($F646-$F66B).
CopyToScreen:
  LD A,B
  LD (CopyColumnAdd+$0001),A
  LD B,$00
  LD IX,ScreenLineTable
  ADD IX,BC
  ADD IX,BC
  LD B,E
  LD C,D
CopyToScreenRow:
  PUSH BC
  LD A,(IX+$00)
CopyColumnAdd:
  ADD A,$00               ; ADD A,n: n the column, written above
  LD E,A
  LD D,(IX+$01)
  INC IX
  INC IX
  LD B,$00
  LDIR
  POP BC
  DJNZ CopyToScreenRow
  RET

  ORG $F9CB

; Six sets of 8 masks, each growing to $FF: RevealText and the front's reveals
; pick a set by a ROM byte
;
; Read by RevealText and the front (front notes). The sets at $F9EB are not
; picked by RevealText (A AND $18 gives 0-3).
DissolveMasks:
  INCBIN "res/resident/dissolve-masks.bin",$0000,48
