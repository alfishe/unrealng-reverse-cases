; --------------------------------------------------------------------------------------------------------------------
; cursor.asm: The pointer and the map box
;
; The arrow pointer drawn over the screen with its saved background, the box of the tool's size it shows over the
; view, and the tool palette's icons.
; --------------------------------------------------------------------------------------------------------------------

; The pointer: an arrow, 8 pixel rows ORed over the screen
; (src/res/graphics/Pointer.png)
;
; Read by DrawPointer $5CFE (L1 156 303 reads of each byte).
PointerShape:
  INCBIN "res/graphics/Pointer.bin",$0000,8
PointerMask:
  INCBIN "res/graphics/Pointer.bin",$0008,8

; the pointer's column in half characters, 0-62 (stage 1's "cursor")
PointerX:
  DEFB $35
PointerY:
  DEFB $01                ; the pointer's row in pixels, 0-184 in steps of 2

; Draw the pointer at its character cell: save the 8 bytes under it, AND the
; mask, OR the arrow
;
; The cell is row PointerY / 8, column PointerX / 2: the pointer moves on the
; character grid (no shift), though its coordinates are finer. The saved bytes
; go to PointerSave $5D34, the address to PointerAt $5D3C. Called by the UI
; loop every pass with ErasePointer after the pass's drawing (L1 158 080).
DrawPointer:
  LD BC,(PointerX)
  SRL B
  SRL B
  SRL B
  SRL C
  CALL ScreenAddr
  LD (PointerAt),HL
  LD IX,PointerSave
  LD IY,PointerMask
  LD DE,PointerShape
  LD B,$08
DrawPointerLoop:
  LD A,(HL)
  LD (IX+$00),A
  LD A,(HL)
  AND (IY+$00)
  LD C,A
  LD A,(DE)
  OR C
  LD (HL),A
  INC DE
  INC IX
  INC IY
  CALL NextPixelLine
  DJNZ DrawPointerLoop
  RET

; The 8 screen bytes under the pointer, and their address
PointerSave:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
PointerAt:
  DEFB $00,$00            ; the display file address of the pointer's cell

; Put the 8 saved bytes back at PointerAt
;
; L1 158 076.
ErasePointer:
  LD HL,(PointerAt)
  LD DE,PointerSave
  LD B,$08
ErasePointerLoop:
  LD A,(DE)
  LD (HL),A
  INC DE
  CALL NextPixelLine
  DJNZ ErasePointerLoop
  RET

; The map cursor's box: width and height in cells (the tool's size, ToolSizes)
;
; Written by ShowTool $6D90; read by TrackBox (L1 81 184 reads).
BoxSize:
  DEFB $01,$01
BoxCell:
  DEFB $00,$00            ; the pointer's cell in the view: column (0-31) and
                          ; row (0-15)
PointerInView:
  DEFB $00                ; nonzero when the pointer is on the map view
                          ; (PointerY $40 or more)
BoxShown:
  DEFB $00                ; 1 when the box is drawn (it fits on the view)

; Work out the pointer's view cell; when the tool's box fits on the view,
; invert it there
;
; Output: PointerInView, BoxCell, BoxShown; the box is the BoxSize cells from
; the pointer's cell, inverted by InvertBox (twice a pass: on, then off once
; drawn). L1 316 156, 40 592 on the view.
TrackBox:
  XOR A
  LD (PointerInView),A
  LD (BoxShown),A
  LD BC,(PointerX)
  LD A,B
  CP $40
  RET C
  LD (PointerInView),A
  LD A,B
  SUB $40
  SRL A
  SRL A
  SRL A
  LD B,A
  LD A,C
  SRL A
  LD C,A
  LD (BoxCell),BC
  LD A,B
  ADD A,$08
  LD B,A
  LD HL,(BoxSize)
  LD A,B
  ADD A,H
  CP $19
  RET NC
  LD A,C
  ADD A,L
  CP $21
  RET NC
  LD A,$01
  LD (BoxShown),A

; Invert (XOR $FF) the BoxSize box at row B, column C of the screen
;
; The tool palette's highlight (ShowTool) and the map cursor (TrackBox). L1 41
; 241.
InvertBox:
  CALL ScreenAddr
  LD BC,(BoxSize)
  SLA B
  SLA B
  SLA B
  LD A,C
  LD (InvertBoxLine+$0003),A
InvertBoxLine:
  PUSH BC
  PUSH HL
  LD B,$00
InvertBoxByte:
  LD A,(HL)
  XOR $FF
  LD (HL),A
  INC L
  DJNZ InvertBoxByte
  POP HL
  POP BC
  CALL NextPixelLine
  DJNZ InvertBoxLine
  RET

; Draw icon tiles A, A+1 (row B) and A+2, A+3 (row B+1) at columns C, C+1
;
; L1 9086.
DrawIcon2x2:
  PUSH BC
  PUSH AF
  CALL DrawIcon
  POP AF
  POP BC
  INC A
  INC C
  PUSH BC
  PUSH AF
  CALL DrawIcon
  POP AF
  POP BC
  DEC C
  INC B
  INC A
  PUSH BC
  PUSH AF
  CALL DrawIcon
  POP AF
  POP BC
  INC A
  INC C
  JP DrawIcon

; The tool palette: 14 icons of 2 x 2 tiles at row 1, columns 2-28, tiles 0, 4,
; 8 ...
;
; L1 649 (each tool change redraws it).
DrawToolIcons:
  LD BC,$0102
  LD D,$0E
  LD E,$00
DrawToolIconsLoop:
  PUSH BC
  PUSH DE
  LD A,E
  CALL DrawIcon2x2
  POP DE
  POP BC
  LD A,E
  ADD A,$04
  LD E,A
  INC C
  INC C
  DEC D
  JR NZ,DrawToolIconsLoop
  RET
