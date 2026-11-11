; --------------------------------------------------------------------------------------------------------------------
; statusview.asm: The Dragonfly title box and the grid position of the status view
;
; The Dragonfly view (DragonflyLoop $6C93) and the status view (StatusLoop $6BC7) are drawn by the resident code in
; bank 2; bank 6 holds the parts they borrow: the boxes behind the Dragonfly's title, the GRID Y / GRID X numbers
; (PrintStatusGrid $C0F7), the map of the status view (module map) and the message of the status views (module panel).
; --------------------------------------------------------------------------------------------------------------------

  ORG $C079

; The attribute box $C0B1 and 8 cleared pixel lines behind the Dragonfly's
; title
;
; Called once by DragonflyTitle `$70B6`. AttrBox `$6CFB` with `$C0B1`, then
; ScreenRowFill `$6D22` of 8 lines of 18 bytes from line `$88`, column 7
; (through DragonflyTitleFill). Witness: L1 1 (play).
DragonflyTitleBox:
  LD HL,DragonflyBoxB
  CALL $6CFB
  LD A,$FF
  EX AF,AF'
  LD A,$08
  LD BC,$0007
  JR DragonflyTitleFill

; An attribute box record (width, height, column, attribute, row) for the
; unused variant $C08E
;
; Read only by DragonflyTitleBoxSmall.
DragonflyTitleBoxes:
  DEFB $41,$0C,$0A,$12,$05

; Variant: the box $C089, then the fill of DragonflyTitleBoxLarge
;
; Known only from the code: nothing calls it.
DragonflyTitleBoxSmall:
  LD HL,DragonflyTitleBoxes
  CALL $6CFB
  JR DragonflyTitleLarge

; Variant: the box $C0AC and 40 cleared lines at column 10
;
; Known only from the code: nothing calls it; its tail DragonflyTitleFill is
; the one DragonflyTitleBox jumps to.
DragonflyTitleBoxLarge:
  LD HL,DragonflyBoxes
  CALL $6CFB
; This entry point is used by the routine at DragonflyTitleBoxSmall.
DragonflyTitleLarge:
  LD A,$FF
  EX AF,AF'
  LD A,$28
  LD BC,$000A
; This entry point is used by the routine at DragonflyTitleBox.
DragonflyTitleFill:
  EXX                     ; A' = $FF, A lines, BC the column: ScreenRowFill of
                          ; 18 bytes from line $88
  LD D,$12
  LD E,$88
  JP $6D22

; Four attribute box records of the Dragonfly title
;
; `$C0AC` read by DragonflyTitleBoxLarge, `$C0B1` by DragonflyTitleBox, `$C0B6`
; by DragonflyTitle (`$70A9`); `$C0BB` is not read in bank 6.
DragonflyBoxes:
  DEFB $6D,$11,$0A,$12,$05
DragonflyBoxB:
  DEFB $6D,$11,$07,$12,$01
DragonflyBoxC:
  DEFB $45,$11,$0A,$12,$05
DragonflyBoxD:
  DEFB $45,$11,$07,$12,$01

; Format the map position: the two numbers in the operands $C0C7 and $C0E2 into
; GridText
;
; The operands are written by DrawStatusMap `$DB1C` from the view's position
; (`$9A6C` and `$9A8E`). Each goes through NumberToDigits `$C126` (leading
; zeros kept, C = `0`) into PaddedDigits `$D9AB`; digits 2-3 and 4-5 are copied
; around the colon of GridText. Witness: L1 40 (m2erbe, missions, play).
FormatGridPosition:
  LD HL,PaddedDigits
  LD C,$30
  EXX
GridYOp:
  LD HL,$270F             ; LD HL,n: n ($C0C7) the Y position
  CALL NumberToDigits
  LD HL,PaddedDigits+$0001
  LD DE,GridText+$0005
  LDI
  LDI
  INC DE
  LDI
  LDI
  LD HL,PaddedDigits
  LD C,$30
  EXX
GridXOp:
  LD HL,$270F             ; LD HL,n: n ($C0E2) the X position
  CALL NumberToDigits
  LD HL,PaddedDigits+$0001
  LD DE,GridText+$000D
  LDI
  LDI
  INC DE
  LDI
  LDI
  RET

; Print the grid position of the status view
;
; Called every frame by StatusLoop `$6BC7`: FormatGridPosition, then
; PrintString `$6FB3` with GridText. Witness: L1 40 (m2erbe, missions, play).
PrintStatusGrid:
  CALL FormatGridPosition
  LD HL,GridText
  CALL $6FB3
  RET

; Text: the two positions "00:00" at line $50 and line $70, column 1
;
; Control code 2 (a pixel line and a column), code 13 (attribute `$47`); the
; digits at `$C106` and `$C10E` are written by FormatGridPosition.
GridText:
  DEFB $02,$50,$01,$0D,$47,$30,$30,$3A,$30,$30,$02,$70,$01,$30,$30,$3A
  DEFB $30,$30,$FF
