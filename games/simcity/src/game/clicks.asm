; --------------------------------------------------------------------------------------------------------------------
; clicks.asm: The pointer's movement and the clicks
;
; MovePointer by the keys (and so the joysticks), Click on SPACE: the palette, the scroll corner, the map (MapClick)
; or the menu bar (OpenMenuAt).
; --------------------------------------------------------------------------------------------------------------------

; Move the pointer by the keys: O left, P right, Q up, A down (the joysticks
; come in as these)
;
; One step a pass for each key held. L1 158 076.
MovePointer:
  LD A,(KeyRowP)
  AND $02
  CALL Z,PointerLeft
  LD A,(KeyRowP)
  AND $01
  CALL Z,PointerRight
  LD A,(KeyRowQ)
  AND $01
  CALL Z,PointerUp
  LD A,(KeyRowA)
  AND $01
  CALL Z,PointerDown
  RET

; PointerX + 1 up to 62
;
; L1 1895.
PointerRight:
  LD HL,PointerX
  LD A,(HL)
  ADD A,$01
  CP $3F
  JP NC,DrawView
  LD (HL),A
  RET

; PointerX - 1 down to 0
;
; L1 2044.
PointerLeft:
  LD HL,PointerX
  LD A,(HL)
  SUB $01
  CP $FF
  JP Z,DrawView
  LD (HL),A
  RET

; PointerY - 2 down to 0
;
; The test of key 6 on the view (KeyRow0 bit 4) leads to a branch no recording
; ran (PointerUpStop, L1 -), which stops at row $40.
PointerUp:
  LD HL,PointerY
  LD A,(HL)
  CP $40
  JR C,PointerUpMove
  LD A,(KeyRow0)
  AND $10
  JR Z,PointerUpStop
PointerUpMove:
  LD A,(HL)
  SUB $02
  CP $FA
  RET NC
  LD (HL),A
  RET
PointerUpStop:
  LD A,(HL)
  SUB $02
  CP $40
  JP C,DrawView
  LD (HL),A
  RET

; PointerY + 2 up to 184
;
; Used by the routine at MovePointer.
PointerDown:
  LD HL,PointerY
  LD A,(HL)
  ADD A,$02
  CP $B9
  JR NC,PointerDownStop
  LD (HL),A
  RET
PointerDownStop:
  LD (HL),$B8
  JP DrawView

; The pointer's character cell when SPACE was pressed: column (0-31), row
; (0-23)
ClickCell:
  DEFB $00,$00
ClickSpare:
  DEFB $00,$00            ; two bytes no code reads

; SPACE pressed: take the pointer's cell, then the tool palette, the scroll
; arrows, the menu bar, the map
;
; With SwitchOff set (no task switch while the UI changes the screen and the
; map): ToolClick $6D51, ScrollClick $6CBF, MenuClick $6401, MapClick $7012. L1
; 609 (the presses of the recordings).
Click:
  LD A,(KeyRowSpace)
  AND $01
  RET NZ
  LD BC,(PointerX)
  SRL B
  SRL B
  SRL B
  SRL C
  LD (ClickCell),BC
  CALL ToolClick
  LD A,$01
  LD (SwitchOff),A
  CALL ScrollClick
  CALL MenuClick
  CALL MapClick
  XOR A
  LD (SwitchOff),A
  RET

; Wait until SPACE is released
;
; L1 709 255 loop runs, 196 calls.
WaitSpaceUp:
  LD A,(KeyRowSpace)
  AND $01
  JR Z,WaitSpaceUp
  RET

; On row 0, open the menu under the pointer and wait for SPACE up
;
; L1 609, 69 on row 0.
MenuClick:
  LD A,(ClickCell+$0001)
  AND A
  RET NZ
  CALL WaitSpaceUp
  CALL OpenMenuAt
  JR WaitSpaceUp

; The menu by the pointer's column: SYSTEM (below 14), OPTIONS (below 30),
; DISASTERS (below 48), WINDOWS
;
; IX = SystemMenu $A02B, OptionsMenu $A32F, DisastersMenu $A43E or WindowsMenu
; $A4C2, then ShowMenu $66F2. L1 69.
OpenMenuAt:
  LD A,(PointerX)
  LD IX,SystemMenu
  CP $0E
  JP C,ShowMenu
  LD IX,OptionsMenu
  CP $1E
  JP C,ShowMenu
  LD IX,DisasterMenu
  CP $30
  JP C,ShowMenu
  LD IX,WindowsMenu
  JP ShowMenu
