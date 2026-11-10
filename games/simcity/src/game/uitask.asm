; --------------------------------------------------------------------------------------------------------------------
; uitask.asm: The UI task
;
; Funds, the date, PassCount; UiTask builds the screen and loops: the pointer, the click, one view row, the periodic
; work (funds, date, tile animation, disasters, advice), the budget window when due, ENTER for the maps.
; --------------------------------------------------------------------------------------------------------------------

; The money (24 bits): 20 000 in the image
Funds:
  DEFB $20,$4E,$7F
FundsSpare:
  DEFB $00
Month:
  DEFB $00                ; 0-11
Year:
  DEFB $6E,$07            ; 16 bits, 1902 in the image
PassSpare:
  DEFB $00

; The UI task's pass counter (Periodic: the movers every 16, the advice every
; 32)
PassCount:
  DEFB $00

; The UI task's start: the simulation task made, the status panel, the start
; menu (A51C), the landscape, the view; then the UI loop
;
; L1 1 (after the mover).
UiTask:
  LD A,$01
  LD (SwitchOff),A
  CALL StartSimulation
  CALL ClearTopBlack
  CALL DrawStatusPanel
  CALL AnimateFlood
  CALL AnimateFire
  LD IX,LevelMenuText
  CALL ClearWindowArea
  CALL DrawMenu
  CALL RunMenu
  CALL NewLandscape
  CALL DrawView
  LD A,$39
  LD (PrintAttr),A
UiLoop:
  CALL DrawPointer        ; draw the pointer, wait (2000 loops), move it, the
                          ; movers, the click, one view row, the periodic work,
                          ; ENTER for the maps
  CALL TrackBox
  LD BC,$07D0
UiDelay:
  DEC BC
  LD A,B
  OR C
  JR NZ,UiDelay
UiPass:
  CALL TrackBox
  CALL ErasePointer
  CALL MovePointer
  CALL DrawMovers
  CALL Click
  LD A,$01
  LD (SwitchOff),A
  CALL DrawViewRowPass
  CALL ShiftScroll
  XOR A
  LD (SwitchOff),A
  CALL Periodic
  CALL ToolKeys
  CALL FundsChanged
  LD A,(BudgetDue)
  AND A
  CALL NZ,BudgetWindow
  LD HL,PassCount
  INC (HL)
  LD A,(MapsDue)
  AND A
  CALL NZ,MapsWindow
  LD A,(KeyRowEnter)
  AND $01
  CALL Z,MapsWindow
  JR UiLoop

; By PassCount: the advice every 32, the movers every 16, and in the 16-pass
; cycle Funds, the date, two tile animations, a disaster, the disaster draw
;
; L1 158 073.
Periodic:
  LD A,(PassCount)
  AND $1F
  CALL Z,ShowAdvice
  LD A,(PassCount)
  AND $0F
  CALL Z,MoveDisasters
  LD A,(PassCount)
  AND $0F
  JP Z,PrintFunds
  CP $01
  JP Z,PrintDate
  CP $02
  JR Z,AnimateFire
  CP $03
  JR Z,AnimateFlood
  CP $04
  JP Z,RunDisaster
  CP $05
  JP Z,RandomDisaster
  RET

; The plane, the tornado, the train
;
; Used by the routine at Periodic.
MoveDisasters:
  CALL MovePlane
  CALL MoveTornado
  JP MoveTrain

; Funds' low 16 bits as last shown
LastFunds:
  DEFW $0000

; When Funds changed: redraw the palette and the tool
;
; Used by the routine at UiTask.
FundsChanged:
  LD DE,(Funds)
  LD HL,(LastFunds)
  AND A
  SBC HL,DE
  RET Z
  LD (LastFunds),DE
  CALL DrawToolIcons
  JP ShowTool

; Tile $45 (fire, $EC90) from one of two frames ($ED38, $ED40) by PassCount bit
; 4: the Random 0-3 added first never carries into it at the Periodic call
; (PassCount AND 15 = 2)
;
; Used by the routines at UiTask and Periodic.
AnimateFire:
  LD DE,CellTiles+$0228
  LD HL,CellTiles+$02D0
  CALL Random
  AND $03
  LD B,A
  LD A,(PassCount)
  ADD A,B
  AND $10
  JR Z,AnimateFireCopy
  LD HL,CellTiles+$02D8
AnimateFireCopy:
  LD BC,$0008
  LDIR
  RET

; Tile $44 (flood, $EC88) from $ED48 or $ED50
;
; Used by the routines at UiTask and Periodic.
AnimateFlood:
  LD DE,CellTiles+$0220
  LD HL,CellTiles+$02E0
  CALL Random
  AND $03
  LD B,A
  LD A,(PassCount)
  ADD A,B
  AND $10
  JR Z,AnimateFloodCopy
  LD HL,CellTiles+$02E8
AnimateFloodCopy:
  LD BC,$0008
  LDIR
  RET
