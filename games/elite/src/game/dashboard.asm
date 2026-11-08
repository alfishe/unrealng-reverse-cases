; --------------------------------------------------------------------------------------------------------------------
; dashboard.asm: The dashboard: the distances to the sun and the planet, the compass, the bars
;
; DashDistances $81A9 runs once a frame in flight: it measures the sun (the cabin temperature, TooClose), the planet
; (the altitude, the safe zone) and points the compass at the planet, or at the station inside the safe zone. DrawBars
; $84D9 redraws the 13 bars whose value changed.
; --------------------------------------------------------------------------------------------------------------------

; DashDistances' results: SunClose, PlanetClose, the compass x and y offsets,
; the compass behind flag
DashWork:
  DEFB $00
SunClose:
  DEFB $00                ; 1 when the sun's coordinates are all below $0100
                          ; (its distance was measured)
PlanetClose:
  DEFB $00                ; 1 when the planet's are all below $0200
CompassX:
  DEFB $00                ; The compass dot's x offset (bit 7 the sign)
CompassY:
  DEFB $00                ; The compass dot's y offset
CompassBehind:
  DEFB $00                ; 1 when the target is behind (z negative): the
                          ; hollow dot

; The sun's and the planet's distances on the bars, the safe zone, the compass
;
; The sun: with all three top bytes clear its distance (VectorLength) gives the
; cabin temperature (BarCabinTemp, through DistanceBand) and below $2000
; SunNear; a distance below $4000 in the other test sets TooClose ($82D1). The
; planet: below $0200 on all axes its distance gives the altitude ($A0 minus
; it, below $4000 TooClose) and SafeZone. The compass points at the planet, or
; at slot 0 (the station) when SafeZone is set and StationLaunch is not $FF:
; each of x and y divided by the distance (CompassDivide) times 8, the sign
; kept; then DrawCompass. f1, w1, d1: 1076 runs.
DashDistances:
  XOR A
  LD (SunClose),A
  LD IX,SunPosition
  LD A,(IX+$02)
  AND $7F
  JR NZ,DashPlanet
  LD A,(IX+$05)
  AND $7F
  JR NZ,DashPlanet
  LD A,(IX+$08)
  AND $7F
  JR NZ,DashPlanet
  CALL VectorLength
  LD A,H
  OR L
  JR Z,DashPlanet
  LD A,$01
  LD (SunClose),A
  EX DE,HL
  LD HL,$0000
  SBC HL,DE
  EX DE,HL
  LD HL,$4000
  AND A
  SBC HL,DE
  JP C,SetTooClose
  LD HL,$2000
  XOR A
  SBC HL,DE
  JR NC,DashDistancesSetSunNear
  LD A,$01
DashDistancesSetSunNear:
  LD (SunNear),A
  EX DE,HL
  CALL DistanceBand
  LD A,H
  LD (BarCabinTemp),A
DashPlanet:
  XOR A
  LD (PlanetClose),A
  LD IX,PlanetPosition
  LD A,(IX+$02)
  AND $7F
  CP $02
  JR NC,DashCompassFar
  LD B,A
  LD A,(IX+$05)
  AND $7F
  CP $02
  JR NC,DashCompassFar
  OR B
  LD B,A
  LD A,(IX+$08)
  AND $7F
  CP $02
  JR NC,DashCompassFar
  OR B
  LD A,$01
  LD (PlanetClose),A
  JR NZ,DashSafe
  CALL VectorLength
  LD A,H
  OR L
  JR Z,DashSafe
  EX DE,HL
  LD HL,$0000
  SBC HL,DE
  EX DE,HL
  LD HL,$4000
  AND A
  SBC HL,DE
  JP C,SetTooClose
  EX DE,HL
  CALL DistanceBand
  LD A,$A0
  SUB H
  LD (BarAltitude),A
DashSafe:
  LD A,$01
  LD (SafeZone),A
  LD A,(StationLaunch)
  INC A
  LD IX,ShipSlots
  JR Z,DashCompassPlanet
  CALL VectorLength
  LD A,H
  OR L
  JR NZ,DashCompassStation
  DEC HL
DashCompassStation:
  EX DE,HL
  PUSH DE
  CALL CompassDivide
  LD (CompassX),A
  INC IX
  INC IX
  INC IX
  POP DE
  CALL CompassDivide
  JR DashCompassStore

; A = the word at IX divided by DE, times 8, with the sign of IX+1
;
; Used by the routine at DashDistances.
CompassDivide:
  XOR A
  LD L,(IX+$00)
  LD H,(IX+$01)
  JR CompassDivideScale
; This entry point is used by the routine at DashDistances.
DashCompassFar:
  XOR A
  LD (SafeZone),A
; This entry point is used by the routine at DashDistances.
DashCompassPlanet:
  INC IX
  CALL VectorLengthAbs
  LD A,H
  OR L
  JR NZ,DashCompassPlanetXY
  DEC HL
DashCompassPlanetXY:
  EX DE,HL
  DEC IX
  PUSH DE
  CALL CompassDivideSigned
  LD (CompassX),A
  INC IX
  INC IX
  INC IX
  POP DE
  CALL CompassDivideSigned
; This entry point is used by the routine at DashDistances.
DashCompassStore:
  LD (CompassY),A
  LD A,(IX+$05)
  AND $80
  LD A,$00
  JR Z,DashCompassSide
  LD A,$01
DashCompassSide:
  LD (CompassBehind),A
  JP DrawCompass

; The same for a 3-byte coordinate at IX (the sign bit cleared first)
;
; Used by the routine at CompassDivide.
CompassDivideSigned:
  LD A,(IX+$00)
  LD L,(IX+$01)
  LD H,(IX+$02)
  RES 7,H

; CompassDivideScale
;
; Used by the routine at CompassDivide.
CompassDivideScale:
  CALL Divide16Vector
  RL B
  RLA
  RL B
  RLA
  RL B
  RLA
  LD H,(IX+$02)
  BIT 7,H
  JR Z,CompassDivideDone
  OR $80
CompassDivideDone:
  RET

; TooClose = 1
;
; Used by the routine at DashDistances.
SetTooClose:
  LD A,$01
  LD (TooClose),A
  RET

; HL = 1.5 * distance; set Condition yellow below $50 pages, red flashing from
; $78
;
; Known from the code only: no recording came that close.
DistanceBand:
  PUSH HL
  ADD HL,HL
  POP DE
  SRL D
  RR E
  ADD HL,DE
  LD A,(Condition)
  LD B,A
  LD A,H
  CP $50
  JR C,DistanceBandNear
DistanceBandFar:
  CP $78
  JR NC,DistanceBandRed
  LD A,B
  CP $63
  RET Z
  LD A,$02
  JR DistanceBandStore
DistanceBandRed:
  LD A,$63
  JR DistanceBandStore
DistanceBandNear:
  LD A,B
  CP $04
  RET NZ
  LD A,$06
DistanceBandStore:
  LD (Condition),A
  RET

; DE, BC, HL = the three top words of the 9-byte vector at IX
;
; Used by the routines at VectorLengthAbs and VectorLength.
LoadVector:
  LD E,(IX+$00)
  LD D,(IX+$01)
  LD C,(IX+$03)
  LD B,(IX+$04)
  LD L,(IX+$06)
  LD H,(IX+$07)
  RET

; VectorLength of the vector at IX with the three signs cleared
;
; Used by the routine at CompassDivide.
VectorLengthAbs:
  CALL LoadVector
  RES 7,H
  RES 7,D
  RES 7,B
  LD A,$01
  JR VectorLengthShift

; HL = the length of the vector at IX: sqrt(x^2 + y^2 + z^2) on the top bytes
;
; The three words are shifted left together until one would overflow (A counts
; the shifts), the top bytes squared from the table at $BE00 (Square $87BF) and
; summed, the square root taken (SqrtVector $9C86), and the result shifted
; back.
VectorLength:
  CALL LoadVector
  LD A,$01

; VectorLengthShift
;
; Used by the routine at VectorLengthAbs.
VectorLengthShift:
  EX DE,HL
  ADD HL,HL
  EX DE,HL
  JR C,VectorLengthX
  SLA C
  RL B
  JR C,VectorLengthY
  ADD HL,HL
  JR C,VectorLengthZ
  ADD A,A
  JR VectorLengthShift
VectorLengthX:
  RR D
  JR VectorLengthSquares
VectorLengthY:
  RR B
  SRL D
  JR VectorLengthSquares
VectorLengthZ:
  RR H
  SRL B
  SRL D
VectorLengthSquares:
  LD C,D
  PUSH AF
  LD A,H
  CALL Square
  EX DE,HL
  LD A,B
  LD B,$00
  CALL Square
  ADD HL,DE
  JR NC,VectorLengthZ2
  INC B
VectorLengthZ2:
  LD A,C
  CALL Square
  ADD HL,DE
  JR NC,VectorLengthSum
  INC B
VectorLengthSum:
  LD A,B
  AND A
  JR Z,VectorLengthRoot
  SRL B
  RR H
  RR L
  SRL B
  RR H
  RR L
  POP AF
  SRL A
  JR Z,VectorLengthBig
  PUSH AF
VectorLengthRoot:
  CALL SquareRootVector
  POP AF
VectorLengthBack:
  SRL A
  JR Z,VectorLengthDone
  SRL H
  RR L
  JP VectorLengthBack
VectorLengthBig:
  CALL SquareRootVector
  ADD HL,HL
  JR NC,VectorLengthDone
  LD HL,$0000
VectorLengthDone:
  RET

; Draw the compass dial and its dot (the solid dot in front, the ring behind)
; in a space view
;
; Used by the routine at CompassDivide.
DrawCompass:
  LD A,(ViewIndex)
  CP $04
  RET NC
  LD HL,CompassDotBehind
  LD A,(CompassBehind)
  AND A
  JR Z,DrawCompassDot
  LD HL,CompassDotFront
DrawCompassDot:
  LD DE,CompassDot
  LD BC,$0008
  LDIR
  LD HL,$5156
  LD A,(CompassY)
  LD B,A
  AND $7F
  JR Z,DrawCompassDial
  LD A,B
  AND $80
  JR NZ,DrawCompassDown
DrawCompassUp:
  LD A,H
  DEC H
  AND $07
  CALL Z,NextLineUp
  DJNZ DrawCompassUp
  JR DrawCompassDial
DrawCompassDown:
  RES 7,B
DrawCompassDownLoop:
  INC H
  LD A,H
  AND $07
  CALL Z,NextLineDown
  DJNZ DrawCompassDownLoop
DrawCompassDial:
  LD (CompassAddress),HL
  CALL DrawCompassDialArt
  LD A,(CompassX)
  LD B,A
  AND $7F
  LD C,A
  JR Z,DrawCompassPlot
  LD A,B
  AND $80
  LD B,C
  JR NZ,DrawCompassLeft
DrawCompassRight:
  LD HL,CompassDot
  LD A,$04
DrawCompassLoop:
  SRL (HL)
  INC HL
  RR (HL)
  INC HL
  DEC A
  JR NZ,DrawCompassLoop
  DJNZ DrawCompassRight
DrawCompassPlot:
  LD DE,(CompassAddress)
  LD HL,CompassDot
  LD BC,$04FF
DrawCompassPlotLine:
  LD A,(DE)
  OR (HL)
  LD (DE),A
  INC E
  INC HL
  LD A,(DE)
  OR (HL)
  LD (DE),A
  EX DE,HL
  INC H
  LD A,H
  AND $07
  CALL Z,NextLineDown
  EX DE,HL
  DEC E
  INC HL
  DJNZ DrawCompassPlotLine
  RET
DrawCompassLeft:
  LD HL,CompassDot
  LD A,$04
DrawCompassLoop2:
  SLA (HL)
  INC HL
  RL (HL)
  INC HL
  DEC A
  JR NZ,DrawCompassLoop2
  DJNZ DrawCompassLeft
DrawCompassPlotLeft:
  LD DE,(CompassAddress)
  LD HL,CompassDot
  LD BC,$04FF
DrawCompassPlotLeftLine:
  LD A,(DE)
  OR (HL)
  LD (DE),A
  INC HL
  DEC E
  LD A,(DE)
  OR (HL)
  LD (DE),A
  EX DE,HL
  INC H
  LD A,H
  AND $07
  CALL Z,NextLineDown
  EX DE,HL
  INC E
  INC HL
  DJNZ DrawCompassPlotLeftLine
  RET

; HL = the next pixel line's row start when L passed a character row (the
; screen's layout)
;
; Used by the routines at DrawCompass, DrawCompassDialArt and DrawScanner.
NextLineDown:
  LD A,L
  ADD A,$20
  LD L,A
  RET C
  LD A,H
  SUB $08
  LD H,A
  RET

; The same going up (known from the code only)
;
; Used by the routines at DrawCompass and DrawScanner.
NextLineUp:
  LD A,L
  SUB $20
  LD L,A
  RET C
  LD A,H
  ADD A,$08
  LD H,A
  RET

; Copy the 24-line dial (CompassDial) to $5035
;
; Used by the routine at DrawCompass.
DrawCompassDialArt:
  LD DE,$5035
  LD HL,CompassDial
  LD BC,$18FF
DrawCompassDialLine:
  LDI
  LDI
  LDI
  DEC E
  DEC E
  DEC E
  EX DE,HL
  INC H
  LD A,H
  AND $07
  CALL Z,NextLineDown
  EX DE,HL
  DJNZ DrawCompassDialLine
  RET

; The screen address of the dot's top line
CompassAddress:
  DEFW $0000

; The dot being drawn: 4 lines of 2 bytes, shifted into place
CompassDot:
  DEFB $3C,$00,$24,$00,$24,$00,$3C,$00

; The dot for a target in front (4 lines of 2 bytes)
CompassDotFront:
  INCBIN "res/dashboard/compass.bin",$0000,8

; The dot for a target behind
CompassDotBehind:
  INCBIN "res/dashboard/compass.bin",$0008,8

; The compass dial: 24 lines of 3 bytes
CompassDial:
  INCBIN "res/dashboard/compass.bin",$0010,72

; Redraw every dashboard bar whose value changed
;
; 11 solid bars (DrawBar) then the roll and pitch markers (DrawMarker, with
; BarMarkerMode 1), each at its address of BarAddresses. f1, w1, d1: 1079 runs,
; 500 bars drawn.
DrawBars:
  LD DE,BarAddresses
  EXX
  LD C,$0B
  EXX
  LD HL,BarForeShield
DrawBarsNext:
  LD A,(HL)
  DEC HL
  CP (HL)
  JR Z,DrawBarsSkip
  LD (HL),A
  SRL A
  SRL A
  PUSH HL
  PUSH DE
  CALL DrawBar
  POP DE
  POP HL
DrawBarsSkip:
  INC DE
  INC DE
  INC HL
  INC HL
  INC HL
  EXX
  DEC C
  EXX
  JR NZ,DrawBarsNext
  LD A,$01
  LD (BarMarkerMode),A
  EXX
  LD C,$02
  EXX
DrawBarsMarker:
  LD A,(HL)
  DEC HL
  CP (HL)
  JR Z,DrawBarsMarkerSkip
  LD (HL),A
  PUSH HL
  PUSH DE
  CALL DrawMarker
  POP DE
  POP HL
DrawBarsMarkerSkip:
  INC DE
  INC DE
  INC HL
  INC HL
  INC HL
  EXX
  DEC C
  EXX
  JR NZ,DrawBarsMarker
  XOR A
  LD (BarMarkerMode),A
  RET

; 1 while the two markers are drawn
BarMarkerMode:
  DEFB $00

; The screen address of each bar's top line: 6 on the left, the speed, the 4
; banks, the roll and the pitch
BarAddresses:
  DEFW $5123
  DEFW $5143
  DEFW $5163
  DEFW $5183
  DEFW $51A3
  DEFW $51C3
  DEFW $5138
  DEFW $5198
  DEFW $51B8
  DEFW $51D8
  DEFW $51F8
  DEFW $5158
  DEFW $5178
  DEFW $51E3

; Draw a roll or pitch marker: a 3-pixel mark at the value
;
; Used by the routine at DrawBars.
DrawMarker:
  LD B,A
  XOR A
  LD (DrawBarLine+$0002),A
  LD (DrawBarWholeLine+$0002),A
  LD A,$03
  LD (DrawBarLength+$0004),A
  JR DrawBarRows

; Draw a bar: 5 bytes wide, A pixels long, 3 pixel lines
;
; Used by the routine at DrawBars.
DrawBar:
  LD B,A
  LD A,$FF
  LD (DrawBarLength+$0004),A
  LD (DrawBarLine+$0002),A
  LD (DrawBarWholeLine+$0002),A

; DrawBarRows
;
; Used by the routine at DrawMarker.
DrawBarRows:
  LD A,(DE)
  LD L,A
  INC DE
  LD A,(DE)
  LD H,A
  EXX
  LD B,$05
  EXX
  LD A,B
  AND A
  JP Z,DrawBarEmpty
DrawBarLength:
  LD D,A
  AND $07
  LD C,$FF
  LD B,A
  LD A,D
  JR Z,DrawBarBytes
  LD A,(BarMarkerMode)
  DEC A
  JP Z,DrawMarkerBits
DrawBarEdge:
  XOR A
DrawBarEdgeBits:
  SCF
  RRA
  DJNZ DrawBarEdgeBits
DrawBarEdgeDone:
  LD C,A
  LD A,D
  ADD A,$08
DrawBarBytes:
  AND $F8
  SRL A
  SRL A
  SRL A
  LD B,A
  LD A,$05
  SUB B
  LD D,A
  JR Z,DrawBarWhole
  DEC B
  JR Z,DrawBarShort
DrawBarFull:
  LD E,B
DrawBarLine:
  PUSH HL
  LD A,$FF
DrawBarFill:
  LD (HL),A
  INC L
  DJNZ DrawBarFill
  CALL BarByte
  INC L
  LD B,D
  DEC B
  JR Z,DrawBarEnd
DrawBarClear:
  XOR A
DrawBarClearByte:
  LD (HL),A
  INC L
  DJNZ DrawBarClearByte
DrawBarEnd:
  LD (HL),$01
  INC L
  POP HL
  EXX
  DEC B
  EXX
  RET Z
  INC H
  LD B,E
  JR DrawBarLine
DrawBarWhole:
  DEC B
  LD E,B
DrawBarWholeLine:
  PUSH HL
  LD A,$FF
DrawBarWholeByte:
  LD (HL),A
  INC L
  DJNZ DrawBarWholeByte
  SET 0,C
  CALL BarByte
  POP HL
  EXX
  DEC B
  EXX
  RET Z
  INC H
  LD B,E
  JR DrawBarWholeLine
DrawBarShort:
  LD B,$05
DrawBarShortLine:
  LD A,C
  PUSH HL
  LD (HL),A
  INC L
  XOR A
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  OR $01
  LD (HL),A
  POP HL
  INC H
  DJNZ DrawBarShortLine
  RET
DrawBarEmpty:
  LD B,$05
DrawBarEmptyLine:
  XOR A
  PUSH HL
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  OR $01
  LD (HL),A
  POP HL
  INC H
  DJNZ DrawBarEmptyLine
  RET
DrawMarkerBits:
  LD A,$80
  DEC B
  JR Z,DrawMarkerDone
  SCF
  RRA
  DEC B
  JR Z,DrawMarkerDone
DrawMarkerShift:
  SRL A
  DJNZ DrawMarkerShift
DrawMarkerDone:
  JP DrawBarEdgeDone

; Write the bar's edge byte C; for a marker keep the frame pixel at the left
;
; Used by the routine at DrawBarRows.
BarByte:
  LD (HL),C
  LD A,(BarMarkerMode)
  DEC A
  RET NZ
  LD A,C
  AND $FE
  CP $80
  JR Z,BarByteFrame
  RET
BarByteFrame:
  DEC L
  LD (HL),$01
  INC L
  RET
