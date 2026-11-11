; --------------------------------------------------------------------------------------------------------------------
; pointer.asm: The mouse pointer: its shapes, the saved background, the save, restore, shift and draw
;
; The menus show a pointer of 8 lines by 16 pixels. The interrupt (InterruptHandler $8383) moves it:
; RestorePointerBackground $D251 puts back the screen bytes saved in PointerBackground $C020, SavePointerBackground
; $D0CA saves the bytes at the new place, DrawPointer $D27C shifts the shape (ShiftPointer $D282, the shape's address
; in its operand $D283) to the pixel and puts it on with its mask (PutPointer $D2F1). Over a 3D window (the title's
; and the stores' model) the pointer goes into the back buffer instead (CopyViewUnderPointer $D142, DrawPointerInView
; $D1BE), so the blit of the view carries it.
;
; The position comes from PointerPos $7DC0 through CopyPointer $897E ($7C51 X, $7C53 Y); the limits of the pointer are
; set from PointerLimits $D32B.
; --------------------------------------------------------------------------------------------------------------------

; The two pointer shapes: 8 lines of a mask byte and a pixel byte each
;
; Line n is two bytes: the mask (`AND` with the screen, shifted in with ones)
; and the pixels (`OR`). ShiftPointer `$D282` reads the shape its operand
; `$D283` points at. The arrow at `$C000` is set by the catalogue, the briefing
; and the stores; the boxed shape at `$C010` by ShowWaitPointer `$CBF4` when a
; screen is left, so it shows while the next one is drawn.
PointerShapes:
ArrowPointer:
  DEFB $00,$00            ; the arrow
  DEFB $00,$7F
  DEFB $00,$7E
  DEFB $00,$7C
  DEFB $00,$7E
  DEFB $00,$77
  DEFB $08,$63
  DEFB $7A,$01
WaitPointer:
  DEFB $00,$FF            ; the boxed shape shown between screens
  DEFB $00,$E3
  DEFB $00,$D5
  DEFB $00,$B6
  DEFB $00,$B0
  DEFB $00,$BE
  DEFB $00,$DD
  DEFB $00,$E3

; The 8 x 2 screen bytes under the pointer
;
; Written by SavePointerBackground `$D0CA` (from the screen) and
; CopyViewUnderPointer `$D142` (from the back buffer), put back by
; RestorePointerBackground `$D251`.
PointerBackground:
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00

  ORG $D0CA

; Save the 8 x 2 screen bytes under the pointer into PointerBackground
;
; The address from `$7C53` (Y) through the line table `$6500` and `$7C51` / 8
; (X), which goes to the operand `$D2FC` for PutPointer. `$9719` = 4. Witness:
; L1 49363 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2,
; search).
SavePointerBackground:
  LD HL,($7C53)
  ADD HL,HL
  LD BC,$6500
  ADD HL,BC
  LD A,($7C51)
  SRL A
  SRL A
  SRL A
  LD (PutPointer+$000B),A
  LD B,$00
  LD C,A
  EXX
  LD DE,PointerBackground
  LD B,$08
SaveBackgroundLoop:
  EXX
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  EX DE,HL
  ADD HL,BC
  EX DE,HL
  PUSH DE
  EXX
  POP HL
  LD A,(HL)
  INC L
  LD (DE),A
  INC E
  LD A,(HL)
  INC L
  LD (DE),A
  INC E
  DJNZ SaveBackgroundLoop
  LD A,$04
  LD ($9719),A
  RET

; The 3D window of the stores for CopyViewUnderPointer and DrawPointerInView
;
; Witness: L1 15 (c1, death, m2erbe, missions, play, play2).
SetStoresWindow:
  LD A,$60
  LD (CopyViewUnderPointer+$0004),A
  LD A,$60
  EX AF,AF'
  LD A,$90
  JR SetViewWindow

; The 3D window of the title menu for the same two
;
; Witness: L1 19 (c1, m2erbe, menu, missions, play, play2).
SetTitleWindow:
  LD A,$FF
  LD (CopyViewUnderPointer+$0004),A
  LD A,$40
  EX AF,AF'
  LD A,$A0

; Patch the window's limits into CopyViewUnderPointer and DrawPointerInView
;
; Input: A the bottom line, A' the top line. Witness: L1 34 (c1, death, m2erbe,
; menu, missions, play, play2).
SetViewWindow:
  LD (CopyViewUnderPointer+$000A),A
  LD (DrawPointerInView+$0004),A
  SUB $08
  LD (CopyViewUnderPointer+$000D),A
  LD (DrawPointerInView+$0007),A
  LD (PointerInViewBottom+$0001),A
  LD (ViewUnderBottom+$0001),A
  EX AF,AF'
  LD (CopyViewUnderPointer+$0011),A
  LD (ViewUnderMiddle+$0004),A
  LD (DrawPointerInView+$000B),A
  LD (PointerInViewMiddle+$0007),A
  SUB $08
  LD (CopyViewUnderPointer+$0015),A
  LD (DrawPointerInView+$000F),A
  RET

; Over the 3D window: take the pointer's background from the back buffer, not
; the screen
;
; Run by the interrupt. Clipped at the window's top and bottom (the operands
; set by SetViewWindow). Witness: L1 2944 (c1, death, m10, m2erbe, m2ocean,
; menu, missions, play, play2, search).
CopyViewUnderPointer:
  LD A,($7C51)
  CP $68
  RET NC
  LD A,($7C53)
  CP $A0
  RET NC
  CP $98
  JR NC,ViewUnderBottom
  CP $40
  JR NC,ViewUnderMiddle
  SUB $38
  RET C
  RET Z
  LD B,A
  LD A,$08
  SUB B
  EXX
  ADD A,A
  LD HL,PointerBackground
  LD E,A
  LD D,$00
  ADD HL,DE
  EX DE,HL
  LD HL,$8AF1
  JR ViewUnderCopy
ViewUnderMiddle:
  LD B,$08
  EXX
  SUB $40
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD DE,$8AF1
  ADD HL,DE
  LD DE,PointerBackground
  JR ViewUnderCopy
ViewUnderBottom:
  SUB $98
  LD B,A
  LD A,$08
  SUB B
  LD B,A
  EXX
  LD A,($7C53)
  LD HL,CopyViewUnderPointer+$0011
  SUB (HL)
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD DE,$8AF1
  ADD HL,DE
  LD DE,PointerBackground
ViewUnderCopy:
  LD A,($7C51)
  SRL A
  SRL A
  SRL A
  LD C,A
  LD B,$00
  ADD HL,BC
  LD C,$1F
  EXX
ViewUnderLoop:
  EXX
  LD A,(HL)
  LD (DE),A
  INC HL
  INC DE
  LD A,(HL)
  LD (DE),A
  INC DE
  ADD HL,BC
  EXX
  DJNZ ViewUnderLoop
  RET

; Over the 3D window: put the shifted pointer (ShiftedPointer) into the back
; buffer
;
; Run by the interrupt; clipped like CopyViewUnderPointer. Witness: L1 2944
; (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).
DrawPointerInView:
  LD A,($7C53)
  CP $A0
  RET NC
  CP $98
  JR NC,PointerInViewBottom
  CP $40
  JR NC,PointerInViewMiddle
  SUB $38
  RET C
  RET Z
  LD B,A
  LD A,$08
  SUB B
  ADD A,A
  ADD A,A
  LD HL,ShiftedPointer+$0002
  LD D,$00
  LD E,A
  ADD HL,DE
  EXX
  LD HL,ShiftedPointer
  LD D,$00
  LD E,A
  ADD HL,DE
  LD DE,$8AF1
  JR PointerInViewDraw
PointerInViewBottom:
  SUB $98
  LD B,A
  LD A,$08
  SUB B
  LD B,A
  LD HL,ShiftedPointer+$0002
  EXX
  LD A,($7C53)
  LD HL,DrawPointerInView+$000B
  SUB (HL)
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD DE,$8AF1
  ADD HL,DE
  EX DE,HL
  LD HL,ShiftedPointer
  JR PointerInViewDraw
PointerInViewMiddle:
  LD B,$08
  LD HL,ShiftedPointer+$0002
  EXX
  SUB $40
  LD L,A
  CALL $A7B7
  LD DE,$8AF1
  ADD HL,DE
  EX DE,HL
  LD HL,ShiftedPointer
PointerInViewDraw:
  EX DE,HL
  LD A,($7C51)
  SRL A
  SRL A
  SRL A
  LD C,A
  LD B,$00
  ADD HL,BC
  EX DE,HL
  LD C,$1F
  EXX
PointerInViewLoop:
  EXX
  LD A,(DE)
  AND (HL)
  INC HL
  EXX
  OR (HL)
  INC HL
  EXX
  LD (DE),A
  INC DE
  LD A,(DE)
  AND (HL)
  INC HL
  INC HL
  INC HL
  EXX
  OR (HL)
  INC HL
  INC HL
  INC HL
  EXX
  LD (DE),A
  EX DE,HL
  ADD HL,BC
  EX DE,HL
  EXX
  DJNZ PointerInViewLoop
  RET

; Put PointerBackground back on the screen at the pointer's old place
;
; Witness: L1 49282 (c1, death, m10, m2erbe, m2ocean, menu, missions, play,
; play2, search).
RestorePointerBackground:
  LD HL,($7C53)
  ADD HL,HL
  LD BC,$6500
  ADD HL,BC
  LD A,(PutPointer+$000B)
  LD B,$00
  LD C,A
  EXX
  LD B,$08
  LD HL,PointerBackground
RestoreBackgroundLoop:
  EXX
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  EX DE,HL
  ADD HL,BC
  EXX
  LD A,(HL)
  INC HL
  EXX
  LD (HL),A
  INC L
  EXX
  LD A,(HL)
  INC HL
  EXX
  LD (HL),A
  EX DE,HL
  EXX
  DJNZ RestoreBackgroundLoop
  RET

; ShiftPointer, then PutPointer
;
; Witness: L1 49399 (c1, death, m10, m2erbe, m2ocean, menu, missions, play,
; play2, search).
DrawPointer:
  CALL ShiftPointer
  JP PutPointer

; Shift the shape at its operand $D283 by X AND 7 into ShiftedPointer (mask
; with ones, pixels with zeros)
;
; Witness: L1 49399 (c1, death, m10, m2erbe, m2ocean, menu, missions, play,
; play2, search).
ShiftPointer:
  LD HL,PointerShapes
  LD DE,ShiftedPointer
  EXX
  LD A,($7C51)
  LD C,A
  AND $07
  LD (ShiftLoop+$0002),A
  LD (ShiftMaskDone+$0007),A
  LD A,C
  SRL A
  SRL A
  SRL A
  LD B,$08
ShiftLoop:
  EXX
  LD A,$00
  AND A
  LD B,A
  LD A,(HL)
  INC HL
  LD C,$FF
  JR Z,ShiftMaskDone
ShiftMask:
  SRA A
  RR C
  OR $80
  DJNZ ShiftMask
ShiftMaskDone:
  EX DE,HL
  LD (HL),A
  INC HL
  LD (HL),C
  INC HL
  EX DE,HL
  LD A,$00
  AND A
  LD B,A
  LD A,(HL)
  INC HL
  LD C,$00
  JR Z,ShiftPixelsDone
ShiftPixels:
  SRL A
  RR C
  DJNZ ShiftPixels
ShiftPixelsDone:
  EX DE,HL
  LD (HL),A
  INC HL
  LD (HL),C
  INC HL
  EX DE,HL
  EXX
  DJNZ ShiftLoop
  RET

; The pointer shifted to the pixel: 8 lines of mask (2 bytes) and pixels (2
; bytes)
;
; Written by ShiftPointer, read by PutPointer and DrawPointerInView.
ShiftedPointer:
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00

; AND the mask and OR the pixels of ShiftedPointer into the screen
;
; Witness: L1 49399 (c1, death, m10, m2erbe, m2ocean, menu, missions, play,
; play2, search).
PutPointer:
  LD HL,($7C53)
  ADD HL,HL
  LD BC,$6500
  ADD HL,BC
  LD B,$00
  LD C,$00
  EXX
  LD HL,ShiftedPointer
  LD DE,ShiftedPointer+$0002
  LD B,$08
PutPointerLoop:
  EXX
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  EX DE,HL
  ADD HL,BC
  LD A,(HL)
  EXX
  AND (HL)
  EX DE,HL
  OR (HL)
  EX DE,HL
  INC DE
  INC HL
  EXX
  LD (HL),A
  INC HL
  LD A,(HL)
  EXX
  AND (HL)
  EX DE,HL
  OR (HL)
  EX DE,HL
  INC DE
  INC HL
  INC HL
  INC HL
  INC DE
  INC DE
  EXX
  LD (HL),A
  EX DE,HL
  EXX
  DJNZ PutPointerLoop
  RET

; Three records of the pointer's limits: X min, X max, Y min, Y max
;
; Copied to `$7D99`, `$7D9B`, `$7DA4`, `$7DA6` by SetPointerLimits: `$D32B` the
; catalogue, `$D32F` the stores, `$D333` the title.
PointerLimits:
  DEFB $08,$F7,$08,$B7
StoresLimits:
  DEFB $08,$F7,$08,$B7
TitleLimits:
  DEFB $08,$F7,$A5,$B7

; SetPointerLimits with $D32F
;
; Witness: L1 15 (c1, death, m2erbe, missions, play, play2).
StoresPointerLimits:
  LD HL,StoresLimits
  JR SetPointerLimits

; SetPointerLimits with $D32B
;
; Witness: L1 51 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2,
; search).
CataloguePointerLimits:
  LD HL,PointerLimits

; Copy the 4 limits at HL to the pointer routine's operands
;
; Witness: L1 85 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2,
; search).
SetPointerLimits:
  LD A,(HL)
  LD ($7D99),A
  INC HL
  LD A,(HL)
  LD ($7D9B),A
  INC HL
  LD A,(HL)
  LD ($7DA4),A
  INC HL
  LD A,(HL)
  LD ($7DA6),A
  RET
