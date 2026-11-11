; --------------------------------------------------------------------------------------------------------------------
; menupointer.asm: The pointer sprite, the marks, the keys
;
; The pointer is an 8 x 8 arrow (PointerSprite: mask and pixels a row) drawn at pixel (x, y) = the operand of LD BC at
; DrawPointer (C = x 0-$F8, B = y 0-$B8), the 16 bytes under it kept in PointerBg. One copy loop serves the save and
; the restore: SavePointerBg writes NOPs into it, RestorePointerBg EX DE,HL (self-modified at BgSwap1 and BgSwap2).
; --------------------------------------------------------------------------------------------------------------------

; Attribute $47 in 10 cells of row A + 9 from HL ($5800 + the column)
;
; A = 1-6 (the item's row - 9). HL: $5800 + the column. The 10 cells may run
; into the next row.
PaintBar:
  ADD A,$09
  LD B,A
  LD DE,$0020
PaintBarRow:
  ADD HL,DE
  DJNZ PaintBarRow
  LD B,$0A
PaintBarCell:
  LD (HL),$47
  INC HL
  DJNZ PaintBarCell
  RET

; Draw the pointer sprite at the position (this LD BC's operand), shifted by x
; AND 7
;
; The mask and the pixels shifted right by x AND 7 (the mask filled with 1s),
; screen = screen AND mask OR pixels over two bytes, eight lines down.
DrawPointer:
  LD BC,$0808
  LD DE,PointerSprite
  LD A,$08
DrawPointerRow:
  PUSH AF
  PUSH BC
  LD A,B
  CALL RomPixelAdd
  PUSH DE
  PUSH HL
  LD A,(DE)
  INC DE
  LD H,A
  LD A,(DE)
  INC DE
  LD D,A
  LD E,$00
  LD L,$FF
  LD A,(DrawPointer+1)
  AND $07
  LD B,A
  JR Z,DrawPointerPut
DrawPointerShift:
  SCF
  RR H
  RR L
  CCF
  RR D
  RR E
  DJNZ DrawPointerShift
DrawPointerPut:
  LD B,H
  LD C,L
  POP HL
  LD A,B
  AND (HL)
  OR D
  LD (HL),A
  INC HL
  LD A,C
  AND (HL)
  OR E
  LD (HL),A
  POP DE
  INC DE
  INC DE
  POP BC
  POP AF
  INC B
  DEC A
  JR NZ,DrawPointerRow
  RET
; This entry point is used by the routine at SetPointerBgWay.
PointerBgCopy:
  LD BC,(DrawPointer+1)     ; 16 bytes between the screen under the pointer and
                            ; PointerBg, the way BgSwap1 / BgSwap2 say
  LD A,$08
  LD DE,PointerBg
PointerBgRow:
  PUSH AF
  PUSH BC
  LD A,B
  CALL RomPixelAdd
BgSwap1:
  NOP                     ; NOP: screen -> PointerBg; EX DE,HL: PointerBg ->
                          ; screen
  LD A,(HL)
  LD (DE),A
  INC HL
  INC DE
  LD A,(HL)
  LD (DE),A
  INC HL
  INC DE
BgSwap2:
  NOP                     ; the same, undone
  POP BC
  POP AF
  INC B
  DEC A
  JR NZ,PointerBgRow
  RET

; The background under the pointer into PointerBg (NOPs into the copy loop)
;
; Used by the routine at MenuRedraw.
SavePointerBg:
  XOR A

; A into BgSwap1 and BgSwap2, then PointerBgCopy
;
; Used by the routine at RestorePointerBg.
SetPointerBgWay:
  LD (BgSwap1),A
  LD (BgSwap2),A
  JR PointerBgCopy

; PointerBg back to the screen (EX DE,HL into the copy loop)
;
; Used by the routine at MenuRedraw.
RestorePointerBg:
  LD A,$EB
  JR SetPointerBgWay

; E (and A) = the menu keys, 0 = pressed: bit 0 P, 1 O, 2 Q, 3 A, 4 SPACE
;
; The four half-rows $DFFE (P, O), $FBFE (Q), $FDFE (A), $7FFE (SPACE). Used by
; the menu and the viewer.
ReadMenuKeys:
  LD BC,$DFFE
  IN A,(C)
  AND $03
  LD E,A
  LD BC,$FBFE
  IN A,(C)
  RLA
  RLA
  AND $04
  OR E
  LD E,A
  LD BC,$FDFE
  IN A,(C)
  RLA
  RLA
  RLA
  AND $08
  OR E
  LD E,A
  LD BC,$7FFE
  IN A,(C)
  RLA
  RLA
  RLA
  RLA
  AND $10
  OR E
  LD E,A
  RET

; 8 rows of mask, pixels: the arrow (src/res/menu99/pointer.png)
PointerSprite:
  INCBIN "res/menu99/pointer.bin",$0000,16

; the 16 screen bytes under the pointer
PointerBg:
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00

; the attributes of rows 10-15 as MenuBottom found them (192 bytes)
SavedAttrs:
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

; the 64-column font, 8 planes of 256 (src/res/menu99/viewer-font.png)
ViewerFont:
  INCBIN "res/menu99/viewer-font.bin",$0000,2048

; 0, CR, LF: the stop in front of TextBuffer for the viewer's Q
TextStart:
  DEFB $00,$0D,$0A
