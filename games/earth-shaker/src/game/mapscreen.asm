; --------------------------------------------------------------------------------------------------------------------
; mapscreen.asm: The map screen (key F): the whole cave as 8 x 8 glyphs
;
; Key F (half row $FD, bit 3) shows the whole 30 x 20 cave once per cave (MapShown $EA8D): ShowMap $EA80 draws a frame
; of MapFrameGlyphs $E9C0, every cell as an 8 x 8 glyph of MapGlyphs $9A00 (DrawMapCells $8059) coloured from MapAttrs
; $9A80 (ColourMapCells $81CC), plays MapTune $E8E8 and redraws the cave window.
; --------------------------------------------------------------------------------------------------------------------

  ORG $8059

; Draw the 600 cells as 8 x 8 glyphs, from the last cell back
;
; HL = the grid's last cell $FFFF, B = 20 rows, C = 30 columns, D = $9A (LD
; D,$9A at $8060); a cell of code k is the glyph MapGlyphs + 8k, printed by
; MapCellGlyph $E9AE at row B, column C.
;
; Witness: L1 1 (timer).
DrawMapCells:
  LD HL,CaveGrid+$0257
  LD B,$14

; LD C,$1E and the first byte of LD D,$9A: bytes that are two instruction
; streams
;
; From $8059 the code runs LD C,$1E ($805E) and LD D,$9A ($8060). The column
; loop's JR NZ,$805F enters at $805F, which runs LD E,$16 and SBC A,$D ($8061):
; both results are overwritten at once (LD A,(HL), LD E,A), so the side entry
; is harmless. mkgame keeps the overlapped bytes as data (the code at $8061 is
; the side entry's).
DrawMapCellsOverlap:
  DEFB $0E,$1E,$16

; The per-cell body of DrawMapCells (entered at SBC A,D)
;
; E = 8 x the cell, MapCellGlyph $E9AE; HL, C and B step down; the row loop
; DJNZ goes back to $805E.
;
; Witness: L1 580 (timer).
DrawMapCellsLoop:
  SBC A,D
  LD A,(HL)
  RLCA
  RLCA
  RLCA
  LD E,A
  PUSH HL
  PUSH BC
  CALL MapCellGlyph
  POP BC
  POP HL
  DEC HL
  DEC C
  JR NZ,DrawMapCellsOverlap+$0001
  DJNZ DrawMapCellsOverlap
  RET

  ORG $81CC

; Colour the map: each cell's attribute from MapAttrs + its code
;
; From the last cell back, 20 rows of 30; MapCellAttr $EAB3 writes the
; attribute (cells from $90 get 0).
;
; Witness: L1 1 (timer).
ColourMapCells:
  LD HL,CaveGrid+$0257
  LD B,$14
ColourMapCellsLoop:
  LD C,$1E
ColourMapCellsLoop2:
  LD DE,MapAttrs
  LD A,(HL)
  PUSH HL
  ADD A,E
  LD E,A
  CALL MapCellAttr
  NOP
  NOP
  POP HL
  DEC HL
  DEC C
  JR NZ,ColourMapCellsLoop2
  DJNZ ColourMapCellsLoop
  RET

  ORG $9A00

; The map's 8 x 8 glyph of each cell code 0-15
MapGlyphs:
  INCBIN "res/graphics/map-glyphs.bin",$0000,128

; The map's attribute of each cell code 0-15
MapAttrs:
  INCBIN "res/tables/map-attrs.bin",$0000,16

; Leftover: code never run (CALL $8059, CALL $81CC, RET; copy 7 bytes to $8D78,
; JP $8B20)
MapPatchLeftover:
  INCBIN "res/leftovers/map-patch.bin",$0000,21

  ORG $E8E1

; Play MapTune
;
; Witness: L1 1 (timer).
PlayMapTune:
  LD HL,MapTune
  CALL PlayTune
  RET

; The map screen's tune
MapTune:
  INCBIN "res/music/map.bin",$0000,198

; Print the map glyph of a cell below $80
;
; Witness: L1 600 (timer).
MapCellGlyph:
  CP $80
  CALL C,PrintGlyph
  RET

; Leftover: the old map attribute write (12 bytes)
MapCellAttrOld:
  INCBIN "res/leftovers/map-attr-old.bin",$0000,12

; The map frame's 8 glyphs
MapFrameGlyphs:
  INCBIN "res/graphics/map-frame.bin",$0000,64

; Draw the map's frame
;
; Witness: L1 1 (timer).
DrawMapFrame:
  LD C,$1E
DrawMapFrameLoop:
  LD B,$00
  LD DE,MapFrameGlyphs+$0008
  PUSH BC
  CALL PrintGlyph
  POP BC
  LD B,$15
  LD DE,MapFrameGlyphs+$0030
  PUSH BC
  CALL PrintGlyph
  POP BC
  DEC C
  JR NZ,DrawMapFrameLoop
  LD B,$14
DrawMapFrameLoop2:
  LD C,$00
  LD DE,MapFrameGlyphs+$0018
  PUSH BC
  CALL PrintGlyph
  POP BC
  LD C,$1F
  LD DE,MapFrameGlyphs+$0020
  PUSH BC
  CALL PrintGlyph
  POP BC
  DJNZ DrawMapFrameLoop2
  LD B,$15
DrawMapFrameLoop3:
  LD C,$00
  LD A,$43
  LD D,$01
  PUSH BC
  CALL FillAttrs
  POP BC
  LD C,$1F
  LD D,$01
  PUSH BC
  CALL FillAttrs
  POP BC
  DJNZ DrawMapFrameLoop3
  LD BC,$0000
  LD DE,MapFrameGlyphs
  CALL PrintGlyph
  LD BC,$1500
  LD DE,MapFrameGlyphs+$0028
  CALL PrintGlyph
  LD BC,$151F
  LD DE,MapFrameGlyphs+$0038
  CALL PrintGlyph
  LD BC,$001F
  LD DE,MapFrameGlyphs+$0010
  CALL PrintGlyph
  LD A,$43
  LD BC,$0000
  LD D,$20
  CALL FillAttrs
  LD BC,$1501
  LD D,$1E
  CALL FillAttrs
  RET

; The map screen
;
; Witness: L1 1 (timer).
ShowMap:
  CALL DrawMapFrame
  CALL DrawMapCells
  CALL ColourMapCells
  CALL PlayMapTune
  RET

; $FF once the map was shown in this cave
MapShown:
  DEFB $00

; MapShown and PlayerKilled 0
;
; Witness: L1 48 (c1, hiscore, lives, timer, rzx x32).
ClearMapFlag:
  XOR A
  LD (MapShown),A
  LD (PlayerKilled),A
  RET

; Key F: the map, once per cave
;
; Its last instruction, CALL DrawWindowAtOrigin $8D75, runs every pass: this is
; where the window is drawn.
;
; Witness: L1 44098 (c1, hiscore, lives, timer, rzx x32).
MapKey:
  LD A,$FD
  OUT ($FF),A
  IN A,($FE)
  AND $08
  JR NZ,MapKeySkip
  LD A,(MapShown)
  CP $FF
  JR Z,MapKeySkip
  LD A,$FF
  LD (MapShown),A
  CALL ShowMap
MapKeySkip:
  CALL DrawWindowAtOrigin
  RET

; The map attribute of a cell, 0 for cells from $90
;
; Witness: L1 600 (timer).
MapCellAttr:
  CP $90
  JR NC,MapCellAttrSkip
  CALL AttrAddr
  LD A,(DE)
  LD (HL),A
  RET
MapCellAttrSkip:
  CALL AttrAddr
  XOR A
  LD (HL),A
  RET
