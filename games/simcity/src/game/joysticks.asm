; --------------------------------------------------------------------------------------------------------------------
; joysticks.asm: The Kempston and Sinclair joysticks, the shift scroll
;
; ReadKempston and ReadSinclair fold the joysticks into KeyRows every interrupt (P O A Q SPACE); ShiftScroll moves the
; view with CAPS SHIFT and 5-8.
; --------------------------------------------------------------------------------------------------------------------

; Fold the Kempston bits into KeyRows: right -> P, left -> O, down -> A, up ->
; Q, fire -> SPACE
;
; Called by ReadInput ($F792) every interrupt; KempstonFound decides its use.
; L1 413 183.
ReadKempston:
  CALL ReadPort1F
  LD C,A
  BIT 0,C
  JR NZ,KempLeft
  LD HL,KeyRowP
  RES 0,(HL)
KempLeft:
  BIT 1,C
  JR NZ,KempDown
  LD HL,KeyRowP
  RES 1,(HL)
KempDown:
  BIT 2,C
  JR NZ,KempUp
  LD HL,KeyRowA
  RES 0,(HL)
KempUp:
  BIT 3,C
  JR NZ,KempFire
  LD HL,KeyRowQ
  RES 0,(HL)
KempFire:
  BIT 4,C
  RET NZ
  LD HL,KeyRowSpace
  RES 0,(HL)
  RET

; With SYMBOL SHIFT and CAPS SHIFT up: keys 7 -> P, 6 -> O, 8 -> A, 9 -> Q, 0
; -> SPACE
;
; The Sinclair (Interface 2, port 2) joystick on keys 6-0: 6 left, 7 right, 8
; down, 9 up, 0 fire. Run every interrupt (L1 413 183); with a shift down it is
; skipped, so SYMBOL SHIFT + digit stays the tool keys. Open point 2.
ReadSinclair:
  LD A,(KeyRowSpace)
  AND $02
  RET Z
  LD A,(KeyRows)
  AND $01
  RET Z
  LD A,(KeyRow0)
  LD C,A
  BIT 3,C
  JR NZ,SincLeft
  LD HL,KeyRowP
  RES 0,(HL)
SincLeft:
  BIT 4,C
  JR NZ,SincDown
  LD HL,KeyRowP
  RES 1,(HL)
SincDown:
  BIT 2,C
  JR NZ,SincUp
  LD HL,KeyRowA
  RES 0,(HL)
SincUp:
  BIT 1,C
  JR NZ,SincFire
  LD HL,KeyRowQ
  RES 0,(HL)
SincFire:
  BIT 0,C
  RET NZ
  LD HL,KeyRowSpace
  RES 0,(HL)
  RET

; CAPS SHIFT with 5, 6, 7, 8: scroll the view a cell left, down, up, right,
; then redraw
;
; L1 158 073.
ShiftScroll:
  LD A,(KeyRows)
  AND $01
  RET NZ
  LD HL,$0000
  LD A,(KeyRow0)
  AND $04
  CALL Z,ScrollRight
  LD A,(KeyRow1)
  AND $10
  CALL Z,ScrollLeft
  LD A,(KeyRow0)
  AND $08
  CALL Z,ScrollUp
  LD A,(KeyRow0)
  AND $10
  CALL Z,ScrollDown
  LD A,H
  OR L
  RET Z
  JP DrawView
