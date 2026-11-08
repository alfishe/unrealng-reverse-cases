; --------------------------------------------------------------------------------------------------------------------
; chartcursor.asm: The charts' crosses: the cursor's cross placed and drawn with XOR, the cursor keys' moves
;
; A chart cross is two XOR lines through (CrossX, CrossY), CrossSize long, clipped to the chart (CrossTop to
; CrossBottom, and the screen's sides): drawing it twice takes it away, so every cursor move is erase, move, draw. The
; galactic chart's cursor cross is 10 pixels and sits at the cursor's chart point (x, y / 2 + 24); the short range
; chart's is 16, at 4 pixels a unit of x and 2 of y from the current system at the chart's centre (97, 96), and is not
; drawn off the chart.
; --------------------------------------------------------------------------------------------------------------------

; The cursor's cross on the chart that is up, by CrossSize: 10 the galactic
; chart, else the short range one (nothing when off it)
;
; 36 runs (f1, d1: the charts and their cursor). The short range point: x = 97
; + 4 (cursor x - current x), y = 96 + 2 (cursor y - current y), refused on any
; overflow and outside rows 25-166.
ChartCross:
  LD A,(CrossSize)
  CP $0A
  JR Z,ChartCrossGalactic
  LD A,(Seeds+$000B)
  LD B,A
  LD A,(ChartCursorX)
  SUB B
  JR C,ChartCrossLeft
  ADD A,A
  RET C
  ADD A,A
  RET C
  LD B,A
  LD A,$61
  ADD A,B
  RET C
  JR ChartCrossY
ChartCrossLeft:
  NEG
  ADD A,A
  RET C
  ADD A,A
  RET C
  LD B,A
  LD A,$61
  SUB B
  RET C
ChartCrossY:
  LD (CrossX),A
  LD A,(Seeds+$0009)
  LD B,A
  LD A,(ChartCursorY)
  SUB B
  JR C,ChartCrossUp
  ADD A,A
  RET C
  LD B,A
  LD A,$60
  ADD A,B
  RET C
  JR ChartCrossRows
ChartCrossUp:
  NEG
  SLA A
  RET C
  LD B,A
  LD A,$60
  SUB B
  RET C
ChartCrossRows:
  CP $19
  RET C
  CP $A7
  RET NC
  LD (CrossY),A
  JR ChartCrossDraw
ChartCrossGalactic:
  LD A,(ChartCursorX)
  LD (CrossX),A
  LD A,(ChartCursorY)
  SRL A
  ADD A,$18
  LD (CrossY),A
ChartCrossDraw:
  JP DrawCross

; S: the cursor two y up (stopping at 0)
;
; Used by the routine at CursorUp.
ChartUp:
  CALL ChartCross
  LD A,(ChartCursorY)
  DEC A
  DEC A
  CP $FE
  JR C,ChartUpStore
  XOR A
ChartUpStore:
  LD (ChartCursorY),A
  JR ChartMoved

; X: two y down (stopping at 255)
;
; Used by the routine at CursorDown.
ChartDown:
  CALL ChartCross
  LD A,(ChartCursorY)
  INC A
  INC A
  CP $02
  JR NC,ChartDownStore
  LD A,$FF
ChartDownStore:
  LD (ChartCursorY),A
  JR ChartMoved

; N: one x left (stopping at 1)
;
; Used by the routine at CursorLeft.
ChartLeft:
  CALL ChartCross
  LD A,(ChartCursorX)
  DEC A
  JR NZ,ChartLeftStore
  INC A
ChartLeftStore:
  LD (ChartCursorX),A
; This entry point is used by the routines at ChartUp, ChartDown, ChartRight
; and ChartHome.
ChartMoved:
  JP ChartCross           ; The cross drawn again at the new place

; M: one x right (stopping at 254)
;
; Used by the routine at CursorRight.
ChartRight:
  CALL ChartCross
  LD A,(ChartCursorX)
  INC A
  CP $FF
  JR NZ,ChartRightStore
  DEC A
ChartRightStore:
  LD (ChartCursorX),A
  JR ChartMoved

; B: the cursor back on the current system
;
; Used by the routine at CursorHome.
ChartHome:
  CALL ChartCross
  LD A,(Seeds+$000B)
  LD (ChartCursorX),A
  LD A,(Seeds+$0009)
  LD (ChartCursorY),A
  JR ChartMoved

; The cross's length in pixels (16 or 24 for the current system's, 10 or 16 for
; the cursor's)
CrossSize:
  DEFB $00

; The chart's first pixel row (24)
CrossTop:
  DEFB $00

; The chart's last pixel row (152 galactic, 167 short range)
CrossBottom:
  DEFB $00

; Two XOR lines through (CrossX, CrossY): the horizontal one cut at the
; screen's edges, the vertical one at CrossTop and CrossBottom
;
; The horizontal line is drawn a byte at a time: a partial byte (a mask of the
; first bit on), whole bytes of $FF, a partial last byte; the three cases are
; the line inside the screen, cut at the left and cut at the right. The
; vertical line steps down the screen's pixel rows (NextRowDown) with one bit.
DrawCross:
  LD A,(CrossSize)
  SRL A
  LD B,A
  LD A,(CrossX)
  SUB B
  JR C,DrawCrossCutLeft
  JR Z,DrawCrossCutLeft
  LD D,A
  LD A,(CrossY)
  LD C,A
  LD A,D
  CALL PixelAddress
  LD A,(CrossX)
  ADD A,B
  JR C,DrawCrossCutRight
  AND $07
  JR NZ,DrawCrossRight
  LD A,$08
DrawCrossRight:
  LD E,A
  LD A,(CrossSize)
  SUB E
  LD C,A
  AND $07
  JR NZ,DrawCrossBytes
  LD D,$08
  LD A,C
  SUB D
  JR DrawCrossCount
DrawCrossBytes:
  LD D,A
  LD A,C
DrawCrossCount:
  AND $F8
  JR Z,DrawCrossShort
  RRA
  RRA
  RRA
  AND $1F
  JP DrawCrossLine
DrawCrossCutLeft:
  LD A,(CrossY)
  LD C,A
  XOR A
  CALL PixelAddress
  LD A,(CrossX)
  ADD A,B
  LD C,A
  AND $07
  JR NZ,DrawCrossCutLeftBits
  LD E,$08
  LD A,C
  SUB E
  JR DrawCrossCutLeftCount
DrawCrossCutLeftBits:
  LD E,A
  LD A,C
DrawCrossCutLeftCount:
  AND $F8
  JR Z,DrawCrossShortLeft
  RRA
  RRA
  RRA
  AND $1F
  JP DrawCrossLineLeft
DrawCrossCutRight:
  LD A,(CrossX)
  LD C,A
  XOR A
  SUB C
  ADD A,B
  LD C,A
  AND $07
  JR NZ,DrawCrossCutRightBits
  LD D,$08
  LD A,C
  SUB D
  JR DrawCrossCutRightCount
DrawCrossCutRightBits:
  LD D,A
  LD A,C
DrawCrossCutRightCount:
  AND $F8
  JR Z,DrawCrossShortRight
  RRA
  RRA
  RRA
  AND $1F
  JP DrawCrossLineRight
DrawCrossShort:
  CALL MaskTop
  CALL MaskLow
  LD A,(HL)
  XOR D
  LD (HL),A
  INC HL
  JR DrawCrossDone
DrawCrossShortLeft:
  CALL MaskTop
  RES 7,E
  JR DrawCrossDone
DrawCrossShortRight:
  CALL MaskLow
  RES 0,D
  JP DrawCrossEndRight

; DrawCrossLine
;
; Used by the routine at DrawCross.
DrawCrossLine:
  LD B,A
  CALL MaskTop
  CALL MaskLow
  LD A,(HL)
  XOR D
  LD (HL),A
  INC HL
DrawCrossFull:
  LD A,(HL)
  XOR $FF
  LD (HL),A
  INC HL
  DJNZ DrawCrossFull
; This entry point is used by the routine at DrawCross.
DrawCrossDone:
  JP DrawCrossEnd
; This entry point is used by the routine at DrawCross.
DrawCrossLineLeft:
  LD B,A
  CALL MaskTop
  LD A,(HL)
  XOR $7F
  LD (HL),A
  INC HL
  DEC B
  JR Z,DrawCrossDone
DrawCrossFullLeft:
  LD A,(HL)
  XOR $FF
  LD (HL),A
  INC HL
  DJNZ DrawCrossFullLeft
  JR DrawCrossDone
; This entry point is used by the routine at DrawCross.
DrawCrossLineRight:
  LD B,A
  CALL MaskLow
  LD A,(HL)
  XOR D
  LD (HL),A
  INC HL
  DEC B
  JR Z,DrawCrossLastRight
DrawCrossFullRight:
  LD A,(HL)
  XOR $FF
  LD (HL),A
  INC HL
  DJNZ DrawCrossFullRight
DrawCrossLastRight:
  LD A,(HL)
  XOR $FE
  LD (HL),A
  JR DrawCrossVertical

; E = a byte with its top E bits set (the leftmost E pixels)
;
; Used by the routines at DrawCross and DrawCrossLine.
MaskTop:
  XOR A
MaskTopLoop:
  SCF
  RRA
  DEC E
  JR NZ,MaskTopLoop
  LD E,A
  RET

; D = a byte with its low D bits set (the rightmost D pixels)
;
; Used by the routines at DrawCross and DrawCrossLine.
MaskLow:
  XOR A
MaskLowLoop:
  SCF
  RLA
  DEC D
  JR NZ,MaskLowLoop
  LD D,A
  RET

; HL = the screen address of x A, row C (the cross's own; the plots use the
; ROM's PIXEL-ADD)
;
; Used by the routines at DrawCross and DrawCrossEnd.
PixelAddress:
  RRA
  RRA
  RRA
  AND $1F
  LD L,A
  LD A,C
  AND $38
  ADD A,A
  ADD A,A
  OR L
  LD L,A
  LD A,C
  AND $07
  OR $40
  LD H,A
  LD A,C
  AND $C0
  RRA
  RRA
  RRA
  AND $1F
  OR H
  LD H,A
  RET

; DrawCrossEnd
;
; Used by the routine at DrawCrossLine.
DrawCrossEnd:
  LD A,(HL)
  XOR E
  LD (HL),A
  JR DrawCrossVertical
; This entry point is used by the routine at DrawCross.
DrawCrossEndRight:
  LD A,(HL)
  XOR D
  LD (HL),A
; This entry point is used by the routine at DrawCrossLine.
DrawCrossVertical:
  LD A,(CrossSize)
  SRL A
  LD B,A
  LD A,(CrossTop)
  LD C,A
  LD A,(CrossY)
  SUB B
  JR C,DrawCrossVerticalTop
  CP C
  JR C,DrawCrossVerticalTop
  LD C,A
  LD A,(CrossX)
  CALL PixelAddress
  LD A,(CrossBottom)
  LD C,A
  LD A,(CrossY)
  ADD A,B
  SUB C
  LD C,A
  LD A,(CrossSize)
  JR C,PixelAddressIfBelow
  SUB C
PixelAddressIfBelow:
  LD B,A
  JR DrawCrossVerticalBit
DrawCrossVerticalTop:
  LD D,A
  LD A,C
  SUB D
  LD D,A
  LD A,(CrossSize)
  SUB D
  LD B,A
  LD A,(CrossX)
  CALL PixelAddress
DrawCrossVerticalBit:
  LD A,(CrossX)
  AND $07
  INC A
  LD C,A
  XOR A
  SCF
  RRA
  DEC C
  JR Z,DrawCrossVerticalNow
DrawCrossVerticalShift:
  SRL A
  DEC C
  JR NZ,DrawCrossVerticalShift
DrawCrossVerticalNow:
  LD E,A
DrawCrossVerticalLoop:
  LD A,(HL)
  XOR E
  LD (HL),A
  INC H
  LD A,H
  AND $07
  CALL Z,NextRowDown
  DJNZ DrawCrossVerticalLoop
  RET

; HL one character row down when the pixel row wrapped past a cell
;
; Used by the routine at DrawCrossEnd.
NextRowDown:
  LD A,L
  ADD A,$20
  LD L,A
  RET C
  LD A,H
  SUB $08
  LD H,A
  RET

; One byte no code reads (known from the code only)
CrossSpare:
  DEFB $00
