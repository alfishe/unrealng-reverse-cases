; --------------------------------------------------------------------------------------------------------------------
; statusview.asm: The console's BRIEF page box and the grid position of the status view
;
; The status view (StatusLoop $6BC7) and its BRIEF page (BriefPage $6C44) are drawn by the resident code in bank 2;
; bank 6 holds the parts they borrow: the boxes behind the briefing text of the BRIEF page, the GRID Y / GRID X
; numbers (PrintStatusGrid $C0F7), the map of the status view (module map) and the message of the status views (module
; panel).
; --------------------------------------------------------------------------------------------------------------------

  ORG $C079

; The attribute box $C0B1 and 8 cleared pixel lines behind the BRIEF page's
; text
;
; Called once by BriefPageText `$70B6`. AttrBox `$6CFB` with `$C0B1`, then
; ScreenRowFill `$6D22` of 8 lines of 18 bytes from line `$88`, column 7
; (through BriefPageFill). Witness: L1 1 (play).
BriefPageBox:
  LD HL,BriefPageBoxB
  CALL $6CFB
  LD A,$FF
  EX AF,AF'
  LD A,$08
  LD BC,$0007
  JR BriefPageFill

; An attribute box record (width, height, column, attribute, row) for the
; unused variant $C08E
;
; Read only by BriefPageBoxSmall.
BriefPageBoxRecord:
  DEFB $41,$0C,$0A,$12,$05

; Variant: the box $C089, then the fill of BriefPageBoxLarge
;
; Known only from the code: nothing calls it.
BriefPageBoxSmall:
  LD HL,BriefPageBoxRecord
  CALL $6CFB
  JR BriefPageLarge

; Variant: the box $C0AC and 40 cleared lines at column 10
;
; Known only from the code: nothing calls it; its tail BriefPageFill is the one
; BriefPageBox jumps to.
BriefPageBoxLarge:
  LD HL,BriefPageBoxes
  CALL $6CFB
; This entry point is used by the routine at BriefPageBoxSmall.
BriefPageLarge:
  LD A,$FF
  EX AF,AF'
  LD A,$28
  LD BC,$000A
; This entry point is used by the routine at BriefPageBox.
BriefPageFill:
  EXX                     ; A' = $FF, A lines, BC the column: ScreenRowFill of
                          ; 18 bytes from line $88
  LD D,$12
  LD E,$88
  JP $6D22

; Four attribute box records of the briefing texts
;
; `$C0AC` read by BriefPageBoxLarge, `$C0B1` by BriefPageBox, `$C0B6` by
; BriefingTextOnce (`$70A8`), `$C0BB` by BriefPageText (`$70C0`); none of the
; four is read inside bank 6.
BriefPageBoxes:
  DEFB $6D,$11,$0A,$12,$05
BriefPageBoxB:
  DEFB $6D,$11,$07,$12,$01
BriefPageBoxC:
  DEFB $45,$11,$0A,$12,$05
BriefPageBoxD:
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
  INCBIN "res/texts/grid-text.bin",$0000,19
