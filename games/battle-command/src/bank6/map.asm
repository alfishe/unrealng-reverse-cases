; --------------------------------------------------------------------------------------------------------------------
; map.asm: The quit prompt and the maps of the status view and the briefing
;
; The status view (StatusLoop $6BC7) and the briefing show the mission's area from above in the 3D window:
; DrawStatusMap $DB1C sets a high view, draws every object of the mission's list (DrawMapObjects $E3F3, models
; MapModels $E512) and three markers (DrawMarker $DB6B, models MarkerModels $E5D5), and BlitMapView $DBBD copies the
; window to the screen. The legend frames and texts are here too, and the quit prompt of the play keys (QuitKey
; $843F).
; --------------------------------------------------------------------------------------------------------------------

  ORG $D9B2

; Clear the screen lines of the quit prompt
;
; Witness: L1 13 (m2erbe, missions, play, play2).
ClearQuitArea:
  LD B,$4F
  LD HL,$6540
ClearQuitLines:
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  PUSH DE
  EXX
  POP HL
  LD (HL),$00
  LD D,H
  LD E,L
  INC DE
  LD BC,$001F
  LDIR
  EXX
  DJNZ ClearQuitLines
  LD B,$08
ClearQuitSides:
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  PUSH DE
  EXX
  POP HL
  LD BC,$000A
  LD (HL),$00
  LD D,H
  LD E,L
  INC DE
  LDIR
  LD C,$0A
  AND A
  SBC HL,BC
  EX DE,HL
  ADD HL,BC
  EX DE,HL
  INC C
  LDIR
  EXX
  DJNZ ClearQuitSides
  EXX
  LD B,$08
ClearQuitEdges:
  EXX
  LD BC,$001B
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  EX DE,HL
  INC L
  LD (HL),$00
  INC L
  LD (HL),$00
  ADD HL,BC
  LD (HL),$00
  INC L
  LD (HL),$00
  EX DE,HL
  EXX
  DJNZ ClearQuitEdges
  RET

; "Are you sure you want to quit? Yes/No.": Y ends the mission, N goes back
;
; ClearQuitArea, the attributes `$5880-$59CA` to `$47`, QuitText, a key: `Y`
; StartViewPass, the shadow screen, the clock stopped, SaveLoadedMission,
; ScreenEight `$704E`; `N` `$8822`, RequestViewBlit, `JP $8872`. Witness: L1 13
; (m2erbe, missions, play, play2).
QuitPrompt:
  CALL ClearQuitArea
  LD HL,$5880
  LD (HL),$47
  LD D,H
  LD E,L
  INC E
  LD BC,$014A
  LDIR
  DEC H
  LD DE,$59D5
  LD C,$0B
  LDIR
  INC E
  LDI
  LDI
  LD DE,$59FD
  LDI
  LDI
  LD HL,QuitText
  CALL $6FB3
QuitKeyLoop:
  LD A,($8978)
  AND $02
  JR Z,QuitKeyLoop
  LD A,($8979)
  CP $59
  JR Z,QuitYes
  CP $4E
  JR NZ,QuitKeyLoop
  CALL $8822
  CALL $988D
  JP $8872
QuitYes:
  CALL $9882
  CALL $7268
  XOR A
  LD ($7DFB),A
  CALL SaveLoadedMission
  JP $704E

; Text: "Are you sure you want to quit?" and "Yes/No."
;
; Printed by QuitPrompt.
QuitText:
  INCBIN "res/texts/quit-text.bin",$0000,46

; The status view's legend frame: the box $DAC6 and 7 cleared lines
;
; Called by StatusLoop `$6BFC`. Witness: L1 10 (m2erbe, missions, play).
StatusMapFrame:
  LD HL,StatusLegendBoxB
  CALL $6CFB
  XOR A
  EX AF,AF'
  LD A,$68
  LD BC,$0007
  EXX
  LD D,$12
  LD E,$28
  JP $6D22

; Text: the map's legend "Roads." and "Rivers." with their glyphs $80 and $81
;
; Printed by StatusMapLegend `$7241`.
StatusLegendText:
  INCBIN "res/texts/status-legend-text.bin",$0000,32

; Attribute box records of the status legend
;
; `$DAC1` read by StatusMapLegend, `$DAC6` by StatusMapFrame.
StatusLegendBoxes:
  DEFB $21,$0C,$07,$12,$01
StatusLegendBoxB:
  DEFB $6D,$11,$07,$12,$01

; The briefing map's legend frame: the box $DB06 and 10 cleared lines
;
; Called by ShowPauseOnce `$7084`. Witness: L1 10 (menu).
BriefingMapFrame:
  LD HL,BriefingLegendBoxB
  CALL $6CFB
  XOR A
  EX AF,AF'
  LD A,$88
  LD BC,$000A
  EXX
  LD D,$12
  LD E,$28
  CALL $6D22
  RET

; Text: "Roads." and "Rivers." for the briefing map
;
; Printed by BriefingMapLegend `$722C`.
BriefingLegendText:
  INCBIN "res/texts/briefing-legend-text.bin",$0000,32

; Attribute box records of the briefing map and the status map
;
; `$DB01` and `$DB0B` read by BriefingMapLegend, `$DB06` by BriefingMapFrame,
; `$DB10` by StatusMapLegend.
BriefingLegendBoxes:
  DEFB $21,$0C,$0A,$12,$05
BriefingLegendBoxB:
  DEFB $6D,$11,$0A,$12,$05
BriefingLegendBoxC:
  DEFB $07,$05,$0A,$12,$11
StatusLegendBoxC:
  DEFB $07,$05,$07,$12,$0D

; DrawStatusMap, then the legend (StatusMapLegend)
;
; Called by StatusLoop `$6C1D`. Witness: L1 40 (m2erbe, missions, play).
StatusMap:
  CALL DrawStatusMap
  CALL $7241
  RET

; The mission's map in the 3D window: a view from above, the objects and three
; markers
;
; The view (`$9A8E` = the operand `$DB1D`, `$9AB3` = `$DB23`, `$9A6C` =
; `$1B58`), MapDepth = 0, StartViewPass, DrawMapObjects, DrawMarker 0 at
; MarkerPosA, 1 at MarkerPosB and 2 at `$67A7` (the player), the view's
; position to GridXOp and GridYOp, RequestViewBlit. Witness: L1 50 (m2erbe,
; menu, missions, play).
DrawStatusMap:
  LD HL,Bank6FillB+$002F
  LD ($9A8E),HL
  LD HL,$FF38
  LD ($9AB3),HL
  LD HL,$1B58
  LD ($9A6C),HL
  XOR A
  LD H,A
  LD L,A
  LD (MapDepth),HL
  LD ($9A93),A
  CALL $9882
  CALL DrawMapObjects
  LD HL,MarkerPosA
  XOR A
  CALL DrawMarker
  LD HL,MarkerPosB
  LD A,$01
  CALL DrawMarker
  LD HL,$67A7
  LD A,$02
  CALL DrawMarker
  LD HL,($9A8E)
  LD (GridXOp+$0001),HL
  LD HL,($9A6C)
  LD (GridYOp+$0001),HL
  CALL $988D
  RET

; DrawStatusMap, then the briefing legend (BriefingMapLegend)
;
; Called by ShowPauseOnce `$7084`. Witness: L1 10 (menu).
BriefingMap:
  CALL DrawStatusMap
  CALL $722C
  RET

; Marker A at the 24-bit position HL: the view moved there, DrawMarkerModel A
;
; Witness: L1 150 (m2erbe, menu, missions, play).
DrawMarker:
  EX AF,AF'
  CALL ReadMapCoord
  EX DE,HL
  LD BC,(DrawStatusMap+$0001)
  ADD HL,BC
  EX DE,HL
  LD ($9A8E),DE
  CALL ReadMapCoord
  EX DE,HL
  LD BC,(DrawStatusMap+$0007)
  ADD HL,BC
  EX DE,HL
  LD ($9AB3),DE
  EX AF,AF'
  CALL DrawMarkerModel
  RET

; DE = the 24-bit coordinate at HL / 16
;
; Witness: L1 300 (m2erbe, menu, missions, play).
ReadMapCoord:
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD A,(HL)
  INC HL
  SRA A
  RR D
  RR E
  SRA A
  RR D
  RR E
  SRA D
  RR E
  SRA D
  RR E
  RET

; The depth word of every vertex DrawMapObjects and DrawMarkerModel make
;
; Written by DrawStatusMap.
MapDepth:
  DEFW $1388

; BlitMapView from line table $6550, column 10
;
; Witness: L1 10 (menu).
SetBriefingBlit:
  LD HL,$6550
  LD A,$0A
; This entry point is used by the routine at SetStatusBlit.
SetMapBlit:
  LD (MapLinesOp+$0001),HL
  LD (MapColumnOp+$0001),A
  RET

; BlitMapView from line table $6510, column 7
;
; Called by StatusLoop `$6BCA`. Witness: L1 10 (m2erbe, missions, play).
SetStatusBlit:
  LD HL,$6510
  LD A,$07
  JR SetMapBlit

; The map's blit: 96 lines of 18 bytes from the back buffer to the screen
;
; Run by the interrupt through ViewBlit `$83E6`; the stack walks the line
; address table (MapLinesOp), the column is MapColumnOp. Witness: L1 50
; (m2erbe, menu, missions, play).
BlitMapView:
  LD (MapBlitSpOp+$0001),SP
MapLinesOp:
  LD SP,$6510             ; LD SP,n: n ($DBC2) the line table
  LD HL,$8AF1
  LD A,$60
  LD B,$00
MapColumnOp:
  LD C,$07                ; LD C,n: n ($DBCC) the column
  POP DE
  EX DE,HL
  ADD HL,BC
  EX DE,HL
  LD C,$12
  LDIR
  LD C,$0E
  ADD HL,BC
  DEC A
  JR NZ,MapColumnOp
MapBlitSpOp:
  LD SP,$0000             ; LD SP,n: n ($DBDC) the saved stack
  RET

; 20 fill bytes ($E5, one $00) of the tape block: never read
Bank6FillA:
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$00,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5

; The mission's catalogue entry: the number of map objects, the marker
; positions, the coordinate tables, the object list
;
; Written by CopyMissionText `$70F6` (2048 bytes, zero in the image). `$DBF3`
; the number of objects, MarkerPosA and MarkerPosB two marker positions (3-byte
; X and Y), MapCoordX and MapCoordY the coordinates by index, MapObjects 6-byte
; object records (two indices, the angle, the model kind).
MissionData:
  DEFB $00
MarkerPosA:
  DEFB $00,$00,$00,$00,$00,$00
MarkerPosB:
  DEFB $00,$00,$00,$00,$00,$00
MapCoordX:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
MapCoordY:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
MapObjects:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00

; Draw each object of MapObjects with its model (kind 0, 6, negative, other; 2
; skipped)
;
; For each 6-byte record: X and Y from the coordinate tables, four corner
; vertices by ProjectMapPoint into the vertex buffers `$FD00`, and RunScript
; `$990F` with IX = MapModels (`$E512` kind 0, `$E534` kind 6, `$E51E`
; negative, `$E52A` other). Witness: L1 50 (m2erbe, menu, missions, play).
DrawMapObjects:
  LD HL,MapObjects
  LD A,(MissionData)
  LD (MapObjectNext+$0002),A
MapObjectLoop:
  PUSH HL
  LD D,$DC
  LD E,(HL)
  EX DE,HL
  LD A,(HL)
  LD (MapObjectLoop+$0051),A
  LD B,A
  LD C,$00
  SRA B
  RR C
  SRA B
  RR C
  LD A,L
  ADD A,$40
  LD L,A
  LD A,(HL)
  LD (ProjectXPositive+$000E),A
  EX DE,HL
  INC HL
  LD E,(HL)
  EX DE,HL
  LD A,(HL)
  LD (MapObjectLoop+$006E),A
  LD A,L
  ADD A,$40
  LD L,A
  LD A,(HL)
  LD (MapObjectLoop+$0069),A
  EX DE,HL
  INC HL
  INC HL
  LD A,(HL)
  LD (MapObjectLoop+$005E),A
  EX AF,AF'
  INC HL
  LD A,(HL)
  LD (MapObjectLoop+$007B),A
  INC HL
  LD A,(HL)
  CP $02
  JP Z,MapObjectNext
  LD (MapObjectLoop+$009B),A
  EX AF,AF'
  EXX
  LD HL,$FD00
  EXX
  CALL ProjectMapPoint
  LD HL,$FD06
  EXX
  LD A,$00
  LD B,A
  LD C,$00
  SRA B
  RR C
  SRA B
  RR C
  LD A,$00
  ADD A,$80
  CALL ProjectMapPoint
  LD HL,$FD02
  EXX
  LD A,$00
  LD (ProjectXPositive+$000E),A
  LD A,$00
  LD B,A
  LD C,$00
  SRA B
  RR C
  SRA B
  RR C
  LD A,$00
  CALL ProjectMapPoint
  EXX
  LD HL,$FD04
  EXX
  LD A,(MapObjectLoop+$006E)
  LD B,A
  LD C,$00
  SRA B
  RR C
  SRA B
  RR C
  LD A,(MapObjectLoop+$007B)
  ADD A,$80
  CALL ProjectMapPoint
  LD A,$00
  AND A
  JP Z,MapModelKind0Sel
  JP M,MapModelNegativeSel
  CP $06
  JR NZ,MapModelOtherSel
  LD IX,MapModelKind6
  JR MapObjectDraw
MapModelOtherSel:
  LD IX,MapModelOther
  JR MapObjectDraw
MapModelNegativeSel:
  LD IX,MapModelNegative
  JR MapObjectDraw
MapModelKind0Sel:
  LD IX,MapModels
MapObjectDraw:
  CALL $990F
MapObjectNext:
  POP HL
  LD A,$00
  DEC A
  JP Z,MapObjectsDone
  LD (MapObjectNext+$0002),A
  LD BC,$0006
  ADD HL,BC
  JP MapObjectLoop
MapObjectsDone:
  RET

; One vertex: X and Y turned by the object's angle (through ApiVector14,
; SinCos8) into the vertex buffers
;
; Witness: L1 2448 (m2erbe, menu, missions, play).
ProjectMapPoint:
  CALL $67E8
  SRA A
  LD H,$00
  AND A
  JP P,ProjectXPositive
  DEC H
ProjectXPositive:
  LD L,A
  ADD HL,BC
  LD A,L
  EXX
  LD (HL),A
  INC L
  EXX
  LD A,H
  EXX
  LD (HL),A
  DEC L
  INC H
  EXX
  LD A,$00
  LD B,A
  LD C,$00
  SRA B
  RR C
  SRA B
  RR C
  EX AF,AF'
  SRA A
  LD H,$00
  AND A
  JP P,ProjectYPositive
  DEC H
ProjectYPositive:
  LD L,A
  ADD HL,BC
  LD A,L
  EXX
  LD (HL),A
  INC L
  EXX
  LD A,H
  EXX
  LD (HL),A
  DEC L
  INC H
  LD BC,(MapDepth)
  LD (HL),C
  INC L
  LD (HL),B
  RET

  ORG $E561

; Marker A: its points (MarkerPointLists) into the vertex buffers, then its
; script (MarkerScripts)
;
; Witness: L1 150 (m2erbe, menu, missions, play).
DrawMarkerModel:
  ADD A,A
  LD HL,MarkerScripts
  LD C,A
  LD B,$00
  ADD HL,BC
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD (MarkerScriptOp+$0002),DE
  LD HL,MarkerPointLists
  ADD HL,BC
  LD E,(HL)
  INC HL
  LD D,(HL)
  EX DE,HL
  LD B,(HL)
  INC HL
  LD E,$00
MarkerPointLoop:
  LD D,$FD
  LD A,(HL)
  INC HL
  EX DE,HL
  LD C,$00
  AND A
  JP P,MarkerXPositive
  DEC C
MarkerXPositive:
  LD (HL),A
  INC L
  LD (HL),C
  DEC L
  INC H
  EX DE,HL
  LD A,(HL)
  INC HL
  EX DE,HL
  LD C,$00
  AND A
  JP P,MarkerYPositive
  DEC C
MarkerYPositive:
  LD (HL),A
  INC L
  LD (HL),C
  DEC L
  INC H
  LD A,(MapDepth)
  LD (HL),A
  INC L
  LD A,(MapDepth+$0001)
  LD (HL),A
  INC L
  EX DE,HL
  DJNZ MarkerPointLoop
MarkerScriptOp:
  LD IX,$0000             ; LD IX,n: n ($E5AC) the script
  CALL $990F
  RET

; The point lists of the three markers
;
; Read by DrawMarkerModel.
MarkerPointLists:
  DEFW MarkerPoints
  DEFW MarkerPointsB
  DEFW MarkerPointsC

; The scripts of the three markers; the third blinks (BlinkMarker)
;
; Read by DrawMarkerModel; `$E5BC` toggled by BlinkMarker.
MarkerScripts:
  DEFW MarkerModels
  DEFW MarkerModelB
  DEFW MarkerModelC

; Toggle the third marker's script between $E5ED and $E5F7
;
; Called by StatusLoop `$6C23`. Witness: L1 40 (m2erbe, missions, play).
BlinkMarker:
  LD HL,(MarkerScripts+$0004)
  AND A
  LD BC,MarkerModelC
  SBC HL,BC
  JR Z,BlinkMarkerReset
  LD (MarkerScripts+$0004),BC
  RET
BlinkMarkerReset:
  LD HL,MarkerModelD
  LD (MarkerScripts+$0004),HL
  RET
