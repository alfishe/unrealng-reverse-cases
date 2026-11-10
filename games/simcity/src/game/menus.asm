; --------------------------------------------------------------------------------------------------------------------
; menus.asm: The menus and dialogs engine
;
; ShowMenu and the inline windows: a description of items (text, toggle, action, number field, separator, end) is
; drawn, the highlight moved with Q / A, SPACE runs the item; number fields are edited in place inside the
; description. MenuHook lets the budget and evaluation windows recompute while they are open.
; --------------------------------------------------------------------------------------------------------------------

; A pull-down menu at IX: the window area cleared, the items drawn, run, then
; the view redrawn
;
; L1 76.
ShowMenu:
  CALL ClearWindowArea
  CALL DrawMenu
  CALL RunMenu
  CALL DrawView
  LD A,$39
  LD (PrintAttr),A
  RET

; A window whose description follows the CALL (POP IX), then ShowWindow
;
; Used by the routines at Confirm, AboutWindow, LoadMenu, SaveMenu,
; FileNameWindow, LoadErrorWindow, TapeWindow, SpeedMenu, LevelMenu and
; SetLevel.
ShowInlineWindow:
  POP IX

; Draw the window at IX: a menu-sized one (first byte 8 or more) over the view,
; else full screen
;
; L1 54.
ShowWindow:
  LD A,(IX+$00)
  CP $08
  JR C,ShowFullWindow
  CALL ClearViewArea
  CALL ClearWindowArea
  CALL DrawMenu
  JP RunMenu
ShowFullWindow:
  CALL ClearTopWhite      ; a full-screen frame (attribute $47), then the items
                          ; and the menu bar again
  CALL PrintInline

; PrintInline codes: a 32 x 24 frame, attribute $47
FullFrameText:
  DEFB $FB,$47,$FD,$00,$00,$20,$18,$FE

; ShowFullWindowItems
ShowFullWindowItems:
  CALL DrawMenu
  CALL RunMenu
  LD A,$39
  LD (PrintAttr),A
  CALL ClearTopBlack
  JP DrawStatusPanel

; Clear rows 8-23 and frame them (attribute $44, a 32 x 16 box at row 8)
;
; L1 116.
ClearWindowArea:
  CALL ClearViewArea
  CALL PrintInline

; PrintInline codes: a 32 x 16 frame at row 8, attribute $44
WindowAreaText:
  DEFB $FB,$44,$FD,$08,$00,$20,$10,$FE

; RET
ClearWindowAreaEnd:
  RET

; The menu being shown: IX of its description, then its line counter and the
; item table
;
; MenuItems ($674A, 3 bytes an item: the line, the item's address) up to $6779,
; MenuValues $677A (3 bytes a line: the column and the address of a number
; field), MenuCount $67C2. L1 6776 reads, 5161 writes.
MenuState:
  DEFB $00,$00
MenuLine:
  DEFB $11                ; the line being drawn
MenuItems:
  DEFB $00,$00            ; the selectable items: line, address
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
MenuValues:
  DEFB $00,$00            ; per line: the column of a number field and its
  DEFB $00,$00            ; address
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
MenuCount:
  DEFB $00                ; the number of selectable items

; Draw the items of the menu at IX, line by line, and collect the selectable
; ones
;
; Item kinds (first byte): 0 a text line, 1 a toggle (a flag address, then ON
; or OFF), 2 an action (an address to run), 3 a separator line (tiles $40-$42),
; 4 the end, 8 a number field (selectable). L1 143.
DrawMenu:
  LD IY,MenuItems
  LD (MenuState),IX
  XOR A
  LD (MenuCount),A
  LD A,(IX+$00)
  LD (MenuLine),A
  INC IX
; This entry point is used by the routines at AddMenuItem, DrawMenuToggleOn and
; DrawMenuToggleNext.
DrawMenuItem:
  LD HL,MenuLine
  INC (HL)
  LD A,$01
  LD (PrintCol),A
  LD A,(IX+$00)
  CP $04
  JR Z,DrawMenuEnd
  CP $02
  JR Z,DrawMenuAction
  CP $03
  JR Z,DrawMenuSeparator
  CP $01
  JR Z,DrawMenuToggle
  CP $00
  JR Z,DrawMenuText
  CP $08
  JR Z,DrawMenuNumber
  RET
DrawMenuNumber:
  CALL AddMenuItem
  JR DrawMenuText
DrawMenuEnd:
  LD (IY+$00),$FF         ; the item table closed with $FF
  RET

; Put the line and IX into the next MenuItems slot
;
; Used by the routines at DrawMenu and DrawMenuToggle.
AddMenuItem:
  LD A,(MenuLine)
  LD (IY+$00),A
  PUSH IX
  POP HL
  LD (IY+$01),L
  LD (IY+$02),H
  LD DE,$0003
  ADD IY,DE
  LD HL,MenuCount
  INC (HL)
  RET
; This entry point is used by the routine at DrawMenu.
DrawMenuAction:
  CALL AddMenuItem
  INC IX
  INC IX
; This entry point is used by the routine at DrawMenu.
DrawMenuText:
  INC IX
  CALL PrintMenuText
  INC IX
  JR DrawMenuItem
; This entry point is used by the routine at DrawMenu.
DrawMenuSeparator:
  INC IX
  LD A,(MenuLine)
  LD B,A
  LD C,$00
  LD (PrintCol),BC
  LD A,$20
  LD (BoxDims),A
  LD A,$40
  LD B,$41
  LD C,$42
  CALL DrawBoxRow
  JR DrawMenuItem

; The toggle's flag value while it is printed
ToggleValue:
  DEFB $00

; A toggle item: its text, then ON or OFF by its flag
;
; Used by the routine at DrawMenu.
DrawMenuToggle:
  CALL AddMenuItem
  INC IX
  LD L,(IX+$00)
  LD H,(IX+$01)
  LD A,(HL)
  LD (ToggleValue),A
  INC IX
  INC IX
  CALL PrintMenuText
  CALL MenuTab
  LD A,(ToggleValue)
  AND A
  JR Z,DrawMenuToggleOff
  CALL PrintInline

; "ON" for a toggle
OnText:
  INCBIN "res/text/inline/On.bin",$0000,3

; DrawMenuToggleOn
DrawMenuToggleOn:
  INC IX
  JP DrawMenuItem
; This entry point is used by the routine at DrawMenuToggle.
DrawMenuToggleOff:
  CALL PrintInline

; "OFF"
OffText:
  INCBIN "res/text/inline/Off.bin",$0000,4

; DrawMenuToggleNext
DrawMenuToggleNext:
  INC IX
  JP DrawMenuItem

; The item's text at its line, column 1: bit 7 ends it; codes $21 (to column
; 24), 5, 6, 7 (numbers)
;
; Codes: $21 moves to column 24 (MenuTab), 6 a 16-bit number (5 digits) at an
; address, 7 an 8-bit one (3 digits), 5 a 24-bit one; a nonzero byte after the
; code registers the field for editing (MenuField). L1 1677.
PrintMenuText:
  LD A,(MenuLine)
  LD B,A
  LD C,$01
  CALL ScreenAddr
  LD (PrintAddr),HL
MenuTextLoop:
  LD A,(IX+$00)
  AND A
  JP P,MenuTextCode
  AND $7F
  CALL PrintChar
  JP NextColumn
MenuTextCode:
  CP $21
  JR Z,MenuTextTab
  CP $06
  JR Z,MenuText16
  CP $07
  JR Z,MenuText8
  CP $05
  JR Z,MenuText24
  CALL PrintChar
  CALL NextColumn
  INC IX
  JR MenuTextLoop
MenuTextTab:
  CALL MenuTab
  INC IX
  JR MenuTextLoop
MenuText16:
  LD A,(IX+$01)
  AND A
  CALL NZ,MenuField
  LD L,(IX+$02)
  LD H,(IX+$03)
  CALL Print5Digits
  LD DE,$0006
  ADD IX,DE
  JR MenuTextLoop
MenuText8:
  LD A,(IX+$01)
  AND A
  CALL NZ,MenuField
  LD L,(IX+$02)
  LD H,$00
  CALL Print3Digits
  LD DE,$0004
  ADD IX,DE
  JR MenuTextLoop
MenuText24:
  LD A,(IX+$01)
  AND A
  CALL NZ,MenuField
  LD L,(IX+$02)
  LD H,(IX+$03)
  LD C,(IX+$04)
  CALL PrintNumber24
  LD DE,$0005
  ADD IX,DE
  JR MenuTextLoop

; HL = MenuValues + 3 A
;
; Used by the routines at MenuField and EditNumber.
MenuValueSlot:
  LD B,A
  ADD A,A
  ADD A,B
  LD C,A
  LD B,$00
  LD HL,MenuValues
  ADD HL,BC
  RET

; Remember the column and the address of the number field on this line
;
; Used by the routine at PrintMenuText.
MenuField:
  LD A,(MenuLine)
  CALL MenuValueSlot
  LD A,(PrintCol)
  LD (HL),A
  PUSH IX
  POP DE
  INC HL
  LD (HL),E
  INC HL
  LD (HL),D
  RET

; PrintCol 24 on this line
;
; Used by the routines at DrawMenuToggle and PrintMenuText.
MenuTab:
  LD A,(MenuLine)
  LD B,A
  LD C,$18
  LD (PrintCol),BC
  CALL ScreenAddr
  LD (PrintAddr),HL
  RET

; XOR $46 into the attributes of row B, columns 1-30: the menu bar's highlight
;
; Used by the routine at ToggleMenuLine.
HighlightLine:
  LD C,$01
  CALL AttrAddr
  LD B,$1E
HighlightLoop:
  LD A,(HL)
  XOR $46
  LD (HL),A
  INC L
  DJNZ HighlightLoop
  RET

; A routine the menu loop calls every pass (0: none): the graph windows' live
; drawing
MenuHook:
  DEFW $0000

; Move the highlight with Q / A every 8 frames (HALT), SPACE selects: run,
; toggle or edit the item
;
; L1 132. The UI task halts here, so the simulation runs on through the switch
; while a menu is open.
RunMenu:
  LD A,(MenuCount)
  AND A
  RET Z
  XOR A
  LD (MenuSelected),A
  CALL CallMenuHook
; This entry point is used by the routines at EditDown and InputGene.
RunMenuShow:
  CALL ToggleMenuLine
RunMenuWait:
  LD B,$08
RunMenuHalt:
  HALT
  DJNZ RunMenuHalt
  LD A,(KeyRowQ)
  AND $01
  CALL Z,MenuUp
  LD A,(KeyRowA)
  AND $01
  CALL Z,MenuDown
  LD A,(KeyRowSpace)
  AND $01
  JR Z,RunMenuRelease
  JR RunMenuWait
RunMenuRelease:
  LD A,(KeyRowSpace)
  AND $01
  JR Z,RunMenuRelease
  CALL SelectedItem
  INC HL
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  LD A,(HL)
  CP $02
  JP Z,MenuAction
  CP $01
  JP Z,MenuToggle
  CP $08
  JR Z,EditNumber
  RET

; The number field being edited: the largest value, its address, its position,
; the key repeat
EditMax:
  DEFB $00
EditPtr:
  DEFB $00
  DEFB $00
EditPos:
  DEFB $00
  DEFB $00
EditRepeat:
  DEFB $14

; Q / A count the field up and down (to EditMax), with a key repeat; SPACE ends
;
; L1 5 (the tax rate and the budget windows).
EditNumber:
  LD A,$0A
  LD (EditRepeat),A
  CALL ToggleMenuLine
  CALL SelectedItem
  LD A,(HL)
  LD (EditPos+$0001),A
  CALL MenuValueSlot
  LD A,(HL)
  LD (EditPos),A
  INC HL
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  INC HL
  INC HL
  LD (EditPtr),HL
  INC HL
  LD A,(HL)
  LD (EditMax),A
  LD A,$45
  LD (PrintAttr),A
EditNumberLoop:
  CALL NumberRepeat
  CALL PrintEditField
  LD A,(KeyRowSpace)
  AND $01
  JR Z,EditNumberDone
  LD A,(KeyRowQ)
  AND $01
  CALL Z,EditUp
  LD A,(KeyRowA)
  AND $01
  CALL Z,EditDown
  CALL CallMenuHook
  LD A,(EditRepeat)
  AND A
  JR Z,EditNumberLoop
  LD B,A
EditNumberHalt:
  HALT
  DJNZ EditNumberHalt
  JR EditNumberLoop

; EditUp
;
; Used by the routine at EditNumber.
EditUp:
  LD A,(EditMax)
  INC A
  LD C,A
  LD HL,(EditPtr)
  LD A,(HL)
  INC A
  CP C
  RET Z
  LD (HL),A
  RET

; EditDown
;
; Used by the routine at EditNumber.
EditDown:
  LD HL,(EditPtr)
  LD A,(HL)
  DEC A
  CP $FF
  RET Z
  LD (HL),A
  RET
; This entry point is used by the routine at EditNumber.
EditNumberDone:
  LD A,(KeyRowSpace)
  AND $01
  JR Z,EditNumberDone
  LD A,$47
  LD (PrintAttr),A
  CALL PrintEditField
  JP RunMenuShow

; Print the field's value in 3 digits at its position
;
; Used by the routines at EditNumber and EditDown.
PrintEditField:
  LD BC,(EditPos)
  CALL ScreenAddr
  LD (PrintAddr),HL
  LD HL,(EditPtr)
  LD L,(HL)
  LD H,$00
  CALL Print3Digits
  RET

; JP (MenuHook) unless 0
;
; Used by the routines at RunMenu and EditNumber.
CallMenuHook:
  LD HL,(MenuHook)
  LD A,H
  OR L
  RET Z
  JP (HL)

; The key repeat: no key, delay 10; a key held, count it down
;
; Used by the routine at EditNumber.
NumberRepeat:
  CALL AnyKey
  JR Z,NumberRepeatReset
  LD HL,EditRepeat
  LD A,(HL)
  AND A
  RET Z
  DEC (HL)
  RET
NumberRepeatReset:
  LD A,$0A
  LD (EditRepeat),A
  RET
; This entry point is used by the routine at RunMenu.
MenuToggle:
  INC HL                  ; flip the flag (XOR 1)
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  LD A,(HL)
  XOR $01
  LD (HL),A
  RET
; This entry point is used by the routine at RunMenu.
MenuAction:
  INC HL                  ; JP to the action
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  JP (HL)

; The highlight one item up
;
; Used by the routine at RunMenu.
MenuUp:
  LD HL,MenuSelected
  LD A,(HL)
  DEC A
  CP $FF
  RET Z
  CALL ToggleMenuLine
  LD (HL),A

; XOR the highlight of the selected item's line
;
; Used by the routines at RunMenu, EditNumber, MenuUp, MenuDown, SetLevel and
; InputGene.
ToggleMenuLine:
  PUSH HL
  PUSH AF
  CALL SelectedItem
  LD B,(HL)
  CALL HighlightLine
  POP AF
  POP HL
  RET

; The highlight one item down
;
; Used by the routine at RunMenu.
MenuDown:
  LD A,(MenuCount)
  LD B,A
  LD HL,MenuSelected
  LD A,(HL)
  INC A
  CP B
  RET Z
  CALL ToggleMenuLine
  LD (HL),A
  JR ToggleMenuLine

; The selected item
MenuSelected:
  DEFB $00

; HL = MenuItems + 3 MenuSelected
;
; Used by the routines at RunMenu, EditNumber and ToggleMenuLine.
SelectedItem:
  LD A,(MenuSelected)
  LD B,A
  ADD A,A
  ADD A,B
  LD C,A
  LD B,$00
  LD HL,MenuItems
  ADD HL,BC
  RET
