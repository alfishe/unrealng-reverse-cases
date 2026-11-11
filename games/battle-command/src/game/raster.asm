; --------------------------------------------------------------------------------------------------------------------
; raster.asm: The 3D view's raster: the back buffer, the blits to the screen, the clear, the projection, the clips, the arithmetic
;
; The 3D view is drawn into a 32 x 96 byte back buffer at $8AF1-$96F0 (256 x 96 pixels, no attributes), cleared with
; PUSH once a pass ($96F1) and copied to the screen by one of three LDI blits that the interrupt runs when the pass is
; done ($83BA). The projection divides with logarithms (DivideByLog $A6D2 and the tables at $5C00); lines and polygons
; are clipped against the near plane in 3D ($A42B, $A509) and against the window in 2D ($A184 here, $C000/$C218 in
; bank 3). The filler and the line drawer live in bank 3 (frag-bank3.ann).
; --------------------------------------------------------------------------------------------------------------------

  ORG $898B

; Another entry of ViewBlitFront: the back buffer from its row 8 ($8BF1) to the
; screen from row 40, 71 rows full width, then the cockpit rows
;
; Saves `SP` at `$8A3E`, HL = `$8BF1`, the row count `$47`, `SP` =
; ScreenRowTable `$6550`, then `JR` into ViewBlitFront's loop at `$89A5`.
; PickupMessage `$DB77` (bank 0) stores it in the blit pointer `$83E6` once the
; goal flag `$68E8` is set (`$DB7C`); m1complete runs it 530 times after its
; goal (frame 16138 on).
ViewBlitLow:
  LD (l_8A27+$0017),SP
  LD HL,BackBuffer+$0100
  LD A,$47
  LD SP,ScreenRowTable+$0050
  JR l_89A5

; Copy the back buffer to the screen rows 32-126: the front view with the
; cockpit cut-outs
;
; With `SP` on ScreenRowTable `$6540` (row 32): 79 rows of 32 bytes (`LDI` x
; 32), then 8 rows of 11 + 11 bytes (the middle 10 bytes skipped, the cockpit),
; then 8 rows of 2 + 2 bytes (the outer columns only). `SP` is saved at
; `$8A3E`. Runs under the interrupt (the routine pointer `$83E6`).
;
; Input: none. Output: the screen bitmap `$4080-$4CCA` (L1). Cost: 97 permille
; of play (the heaviest single routine of the view).
;
; Witness: L1 3600 (c1, death, m2erbe, missions, play, play2).
ViewBlitFront:
  LD (l_8A27+$0017),SP
  LD HL,BackBuffer
  LD A,$4F
  LD SP,ScreenRowTable+$0040
; This entry point is used by the routine at ViewBlitLow.
l_89A5:
  LD BC,$0C00
l_89A8:
  POP DE
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  DEC A
  JR NZ,l_89A8
  LD A,$08
l_89EE:
  POP DE
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LD BC,$000A
  ADD HL,BC
  EX DE,HL
  ADD HL,BC
  EX DE,HL
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  DEC A
  JR NZ,l_89EE
  LD A,$08
l_8A27:
  POP DE
  INC HL
  INC E
  LDI
  LDI
  LD BC,$001A
  ADD HL,BC
  EX DE,HL
  ADD HL,BC
  EX DE,HL
  LDI
  LDI
  INC HL
  DEC A
  JR NZ,l_8A27
  LD SP,$0000
  RET

; Copy the 86 top rows of the back buffer to the screen rows 64-149, full width
;
; `SP` on ScreenRowTable `$6580` (row 64), 86 rows of 32 bytes. Used by the
; menus and the console views (11 recordings).
;
; Witness: L1 458 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions,
; play, play2, search).
ViewBlitWide:
  LD (l_8A50+$0045),SP
  LD SP,ScreenRowTable+$0080
  LD HL,BackBuffer
  LD A,$56
  LD BC,$0C00
l_8A50:
  POP DE
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  DEC A
  JR NZ,l_8A50
  LD SP,$0000
  RET

; Copy 95 rows of 22 bytes (back-buffer columns 5-26) to the screen rows 40-134
; at column 6
;
; `SP` on ScreenRowTable `$6550` (row 40); each row `INC E` x 6, 22 `LDI`, skip
; 10. Only the play recording runs it (the binoculars or the rear view).
;
; Witness: L1 24 (play).
ViewBlitNarrow:
  LD (l_8AA7+$0042),SP
  LD SP,ScreenRowTable+$0050
  LD HL,BackBuffer+$0005
  LD A,$5F
  LD BC,$0840
l_8AA7:
  POP DE
  INC E
  INC E
  INC E
  INC E
  INC E
  INC E
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LD (l_8AA7+$003C),BC
  LD BC,$000A
  ADD HL,BC
  LD BC,$0000
  DEC A
  JR NZ,l_8AA7
  LD SP,$0000
  RET

; Clear the blit request `$83BA`: the interrupt's last job after a view blit
;
; Witness: L1 6657 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions,
; play, play2, search).
ClearBlitRequest:
  XOR A
  LD (BlitRequest+$0001),A
  RET

; The 3D view's back buffer: 96 rows of 32 bytes (256 x 96 pixels, row 0 at the
; top)
;
; Cleared by ClearBackBuffer `$96F1`, drawn by the span filler (bank 3
; `$C86A`), the line drawer (bank 3 `$C9A7`) and PlotBackBuffer `$AA27`, read
; by the three blits. Row y starts at `$8AF1` + 32y. Its last 113 bytes
; (`$9680-$96F0`) are what game.ann calls InputLeftover: they are back-buffer
; rows 92-95, zeroed every pass.
BackBuffer:
  DEFB $F3,$3E,$10,$01,$FD,$7F,$ED,$79,$31,$00,$82,$01,$FE,$7F,$ED,$78,$1F,$1F,$38,$FA,$DD,$21,$3D,$8B,$06,$08,$C5,$78,$3D,$01,$FD,$7F
  DEFB $ED,$79,$DD,$6E,$00,$DD,$66,$01,$DD,$4E,$02,$DD,$7E,$03,$11,$04,$00,$DD,$19,$A7,$28,$10,$47,$DD,$E5,$E5,$DD,$E1,$87,$57,$AF,$5F
  DEFB $3D,$CD,$C1,$86,$DD,$E1,$C1,$10,$D1,$C3,$F4,$68,$00,$C0,$0C,$20,$00,$C0,$2C,$1D,$00,$C0,$49,$20,$00,$C0,$69,$07,$00,$C0,$70,$0A
  DEFB $01,$C3,$7A,$1F,$00,$C0,$00,$00,$00,$C0,$99,$20,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; Zero the back buffer `$8AF1-$96F0` with 1536 PUSH HL
;
; Under `DI`: `SP` saved at `$9711`, `SP` = `$96F1`, HL = 0, 96 x 16 `PUSH HL`,
; `SP` back, `EI`. An interrupt in this time is lost (WALKTHROUGH section 1).
; Once per 3D pass: its count is the number of passes (705 in play).
;
; Witness: L1 6643 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions,
; play, play2, search).
ClearBackBuffer:
  DI
  LD (l_96FE+$0013),SP
  LD SP,ClearBackBuffer
  LD H,$00
  LD L,H
  LD B,$60
l_96FE:
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  DJNZ l_96FE
  LD SP,$0000
  EI
  RET

  ORG $A184

; Clip the line (HL, DE) - (HL', DE') (x, y words) to the window; carry =
; something to draw, H, L, D, E = the ends as bytes
;
; Witness: L1 6164 (c1, death, m2erbe, menu, missions, play, play2).
ClipLine2D:
  CALL ClipLineCodes
  JP NC,l_A191
  LD H,L
  LD L,E
  PUSH HL
  EXX
  LD H,L
  LD L,E
  POP DE
l_A191:
  RET

; Cohen-Sutherland: both out codes (`$A3AC`), reject, accept, or cut an end by
; bisection (`$A1B3`, `$A218`)
;
; Witness: L1 6164 (c1, death, m2erbe, menu, missions, play, play2).
ClipLineCodes:
  CALL OutCode
  LD C,A
  EXX
  CALL OutCode
  LD C,A
  EXX
  LD B,A
  OR C
  JP Z,ClipAccept
  LD A,B
  AND C
  JP NZ,ClipReject
  LD A,B
  AND A
  JR Z,l_A1AE
  LD A,C
  AND A
  JR NZ,l_A201
l_A1AE:
  LD A,B
  AND A
  JR NZ,ClipOneEnd
  EXX

; One end outside: find the crossing of the window edge by bisection (`$A2BA`,
; `$A2CA`, `$A2F3`, `$A352`)
;
; Witness: L1 160 (missions).
ClipOneEnd:
  LD (ClipWindow+$0004),HL
  LD (ClipWindow+$0006),DE
  CALL SwapLineEnds
  LD A,H
  RRA
  JR C,l_A1CB
  RRA
  JR C,l_A1E9
  RRA
  JP C,ClipToBottom
  JP ClipToRight
l_A1CB:
  EXX
  LD HL,(ClipWindow+$0002)
  AND A
  SBC HL,BC
  LD B,H
  LD C,L
  LD HL,(ClipWindow+$0002)
  AND A
  SBC HL,DE
  EX DE,HL
  EXX
  BIT 2,H
  JP NZ,ClipToCorner
  BIT 3,H
  JP NZ,l_A315
  JP ClipToLeft
l_A1E9:
  BIT 2,H
  JP NZ,l_A32C
  BIT 3,H
  JP NZ,l_A305
  JP l_A2EC

; Swap the two ends of the line between the register sets
;
; Witness: L1 273 (death, missions).
SwapLineEnds:
  PUSH HL
  EXX
  PUSH DE
  LD B,H
  LD H,C
  LD C,L
  EXX
  POP BC
  EXX
  POP DE
  RET
; This entry point is used by the routine at ClipLineCodes.
l_A201:
  LD (InputState),BC
  LD (l_A26E+$0009),HL
  LD (l_A26E+$000C),DE
  EXX
  LD (l_A26E+$0019),HL
  LD (l_A26E+$001C),DE
  EXX
  CALL SwapLineEnds

; Both ends outside on different sides: bisect for the middle point, then clip
; each half
;
; Entered by a jump, never called (the survey counts 0 calls).
;
; Witness: L1 0 (missions).
ClipBothEnds:
  LD H,B
  LD L,C
  LD A,H
  AND A
  JR NZ,l_A225
  LD A,(ClipWindow)
  DEC A
  CP L
  JR C,l_A22F
l_A225:
  EX AF,AF'
  LD A,D
  AND A
  JR NZ,l_A22E
  EX AF,AF'
  CP E
  JR C,l_A22F
l_A22E:
  INC HL
l_A22F:
  ADD HL,DE
  SRA H
  RR L
  EXX
  LD H,B
  LD L,C
  LD A,H
  AND A
  JR NZ,l_A242
  LD A,(ClipWindow+$0002)
  DEC A
  CP L
  JR C,l_A24C
l_A242:
  EX AF,AF'
  LD A,D
  AND A
  JR NZ,l_A24B
  EX AF,AF'
  CP E
  JR C,l_A24C
l_A24B:
  INC HL
l_A24C:
  ADD HL,DE
  SRA H
  RR L
  PUSH HL
  EXX
  LD (l_A29F+$0002),DE
  POP DE
  CALL OutCode
  AND A
  JR Z,l_A26E
  LD D,A
  LD A,(InputState)
  AND D
  JR Z,l_A29F
  LD A,(InputState+$0001)
  AND D
  JR Z,l_A2AF
  JP ClipReject
l_A26E:
  LD (l_A26E+$0024),HL
  LD (l_A26E+$0027),DE
  EXX
  LD HL,$0000
  LD DE,$0000
  LD A,(InputState)
  LD C,A
  EXX
  CALL ClipOneEnd
  PUSH HL
  PUSH DE
  LD HL,$0000
  LD DE,$0000
  LD A,(InputState+$0001)
  LD C,A
  EXX
  LD HL,$0000
  LD DE,$0000
  CALL ClipOneEnd
  EXX
  POP DE
  POP HL

; Both ends inside: carry set
;
; Witness: L1 4885 (c1, death, m2erbe, menu, missions, play, play2).
ClipAccept:
  SCF
  RET
; This entry point is used by the routine at ClipBothEnds.
l_A29F:
  LD A,D
  LD DE,$0000
  LD (InputState+$0001),A
  LD B,H
  LD C,L
  EXX
  LD B,H
  LD C,L
  EXX
  JP ClipBothEnds
; This entry point is used by the routine at ClipBothEnds.
l_A2AF:
  LD A,D
  LD (InputState),A
  EX DE,HL
  EXX
  EX DE,HL
  EXX
  JP ClipBothEnds

; Bisect the outside end towards the right edge
;
; Witness: L1 120 (death, missions).
ClipToRight:
  CALL ClipBisectStep
  EXX
; This entry point is used by the routine at ClipToBottom.
l_A2BE:
  PUSH HL
  LD HL,(ClipWindow+$0004)
  LD DE,(ClipWindow+$0006)
  EXX
  POP DE
  SCF
  RET

; Bisect the outside end towards the bottom edge
;
; Witness: L1 80 (death, missions).
ClipToBottom:
  LD HL,(ClipWindow)
  AND A
  SBC HL,BC
  LD B,H
  LD C,L
  LD HL,(ClipWindow)
  AND A
  SBC HL,DE
  EX DE,HL
  CALL ClipBisectStep
  EXX
  EX DE,HL
  LD HL,(ClipWindow)
  EXX
  LD HL,(ClipWindow+$0004)
  LD DE,(ClipWindow+$0006)
  EXX
  SCF
  RET
; This entry point is used by the routine at ClipOneEnd.
l_A2EC:
  EXX
  CALL ClipBisectStep
  JP l_A2BE

; Bisect the outside end towards the left edge
;
; Witness: L1 14 (missions).
ClipToLeft:
  EXX
  CALL ClipBisectStep
  LD HL,(ClipWindow+$0004)
  LD DE,(ClipWindow+$0006)
  EXX
  LD DE,(ClipWindow+$0002)
  SCF
  RET
; This entry point is used by the routine at ClipOneEnd.
l_A305:
  CALL BisectToInside
  PUSH HL
  LD HL,(ClipWindow+$0004)
  LD DE,(ClipWindow+$0006)
  EXX
  EX DE,HL
  POP HL
  SCF
  RET
; This entry point is used by the routine at ClipOneEnd.
l_A315:
  EXX
  CALL BisectToInside
  EX DE,HL
  LD HL,(ClipWindow+$0002)
  AND A
  SBC HL,DE
  PUSH HL
  LD HL,(ClipWindow+$0004)
  LD DE,(ClipWindow+$0006)
  EXX
  POP DE
  SCF
  RET
; This entry point is used by the routine at ClipOneEnd.
l_A32C:
  LD HL,(ClipWindow)
  AND A
  SBC HL,BC
  LD B,H
  LD C,L
  LD HL,(ClipWindow)
  AND A
  SBC HL,DE
  EX DE,HL
  CALL BisectToInside
  EX DE,HL
  LD HL,(ClipWindow)
  AND A
  SBC HL,DE
  PUSH HL
  LD HL,(ClipWindow+$0004)
  LD DE,(ClipWindow+$0006)
  EXX
  EX DE,HL
  POP HL
  SCF
  RET

; Bisect the outside end towards a corner (two edges)
;
; Witness: L1 3 (death, missions).
ClipToCorner:
  LD HL,(ClipWindow)
  AND A
  SBC HL,BC
  LD B,H
  LD C,L
  LD HL,(ClipWindow)
  AND A
  SBC HL,DE
  EX DE,HL
  CALL BisectToInside
  EX DE,HL
  LD HL,(ClipWindow)
  AND A
  SBC HL,DE
  PUSH HL
  LD HL,(ClipWindow+$0004)
  LD DE,(ClipWindow+$0006)
  EXX
  EX DE,HL
  LD HL,(ClipWindow+$0002)
  AND A
  SBC HL,DE
  EX DE,HL
  POP HL
  SCF
  RET

; Both ends outside on one side: no carry
;
; Witness: L1 1168 (death, missions, play, play2).
ClipReject:
  AND A
  RET

; One bisection step of the outside end towards the window
;
; Witness: L1 214 (death, missions).
ClipBisectStep:
  LD H,D
  LD L,E
  INC HL
  ADD HL,BC
  SRA H
  RR L
  EXX
  LD H,D
  LD L,E
  INC HL
  ADD HL,BC
  SRA H
  RR L
  EXX
  LD A,H
  AND A
  JP M,l_A3A4
  LD D,H
  LD E,L
  EXX
  LD D,H
  LD E,L
l_A39D:
  EXX
  LD A,H
  OR L
  JP NZ,ClipBisectStep
  RET
l_A3A4:
  LD B,H
  LD C,L
  EXX
  LD B,H
  LD C,L
  JP l_A39D

; The out code of the point (HL, DE): 8 x < 0, 4 x > `$A17C`, 2 y < 0, 1 y >
; `$A17E`
;
; Witness: L1 12480 (c1, death, m2erbe, menu, missions, play, play2).
OutCode:
  LD A,H
  AND A
  JP M,l_A3D3
  JP NZ,l_A3CE
  LD A,(ClipWindow)
  CP L
  JP C,l_A3CE
  XOR A
l_A3BC:
  EX AF,AF'
  LD A,D
  AND A
  JP M,l_A3D8
  JP NZ,l_A3DC
  LD A,(ClipWindow+$0002)
  CP E
  JP C,l_A3DC
  EX AF,AF'
  RET
l_A3CE:
  LD A,$04
  JP l_A3BC
l_A3D3:
  LD A,$08
  JP l_A3BC
l_A3D8:
  EX AF,AF'
  OR $02
  RET
l_A3DC:
  EX AF,AF'
  OR $01
  RET

; Bisect the segment until the midpoint lies on the window edge
;
; Witness: L1 3 (death, missions).
BisectToInside:
  EXX
l_A3E1:
  LD H,B
  LD L,C
  INC HL
  ADD HL,DE
  SRA H
  RR L
  EXX
  LD H,B
  LD L,C
  INC HL
  ADD HL,DE
  SRA H
  RR L
  LD A,H
  AND A
  JP M,l_A41A
  OR L
  JP Z,l_A40D
  EXX
  LD A,H
  AND A
  JP M,l_A419
  OR L
  JP Z,l_A413
  LD D,H
  LD E,L
  EXX
  LD D,H
  LD E,L
  JP BisectToInside
l_A40D:
  EXX
  LD A,H
  AND A
  JP NZ,l_A419
l_A413:
  LD D,H
  LD E,L
  EXX
  LD D,H
  LD E,L
  RET
l_A419:
  EXX
l_A41A:
  LD B,H
  LD C,L
  EXX
  LD B,H
  LD C,L
  JP l_A3E1

; The other end of a line behind the eye too: no carry (skip the line); else
; NearClipLine
;
; Witness: L1 266 (death, missions).
NearClipLineEnd:
  EXX
  LD A,H
  XOR $80
  OR L
  JR NZ,NearClipLine
  AND A
  RET

; Cut the 3D segment V[B] - V[B'] at the near plane by bisection and project
; the cut: carry, HL / HL' = the screen point
;
; Reads both ends with `$A4D1` / `$A4F1` (vertex + the object position
; operands), halves the segment until depth - 96 is 0, then projects the point
; (Divide `$A687`, DivideByLog `$A6D2`, NegHL `$A771`) like OpProject.
; `$67B2-$67B5` hold the depths being halved.
;
; Witness: L1 3110 (c1, death, m2erbe, missions, play, play2).
NearClipLine:
  PUSH HL
  PUSH DE
  CALL FetchVertexXY
  LD (WorldVars+$0010),HL
  CALL FetchVertexDepth
  CALL FetchVertexXY
  LD (WorldVars+$0012),HL
  CALL FetchVertexDepth
  PUSH BC
  EXX
  EX DE,HL
  POP DE
  PUSH HL
  EXX
  POP BC
  EXX
l_A447:
  LD H,D
  LD L,E
  INC HL
  ADD HL,BC
  SRA H
  JP M,l_A477
  RR L
  EX DE,HL
  LD A,H
  OR L
  JP Z,l_A49A
  EXX
  EX DE,HL
  INC HL
  ADD HL,BC
  SRA H
  RR L
  EX DE,HL
  PUSH BC
  LD HL,(WorldVars+$0010)
  LD BC,(WorldVars+$0012)
  INC HL
  ADD HL,BC
  SRA H
  RR L
  LD (WorldVars+$0010),HL
  POP BC
  EXX
  JP l_A447
l_A477:
  RR L
  LD B,H
  LD C,L
  EXX
  LD H,B
  LD L,C
  INC HL
  ADD HL,DE
  SRA H
  RR L
  PUSH HL
  LD HL,(WorldVars+$0010)
  LD BC,(WorldVars+$0012)
  INC HL
  ADD HL,BC
  SRA H
  RR L
  LD (WorldVars+$0012),HL
  POP BC
  EXX
  JP l_A447
l_A49A:
  LD HL,(WorldVars+$0010)
  LD BC,(WorldVars+$0012)
  INC HL
  ADD HL,BC
  SRA H
  RR L
  EXX
  EX DE,HL
  INC HL
  ADD HL,BC
  SRA H
  RR L
  LD DE,(l_9A5E+$0014)
  CALL Divide
  LD BC,(l_9A9E+$0005)
  ADD HL,BC
  PUSH HL
  PUSH DE
  EXX
  POP DE
  CALL DivideByLog
  CALL NegHL
  LD BC,(l_9A9E+$001D)
  ADD HL,BC
  EX DE,HL
  POP HL
  EXX
  POP DE
  POP HL
  SCF
  RET

; x + `$9A8E` of V[B] to `$A503`, y + `$9AB3` to HL
;
; Witness: L1 6220 (c1, death, m2erbe, missions, play, play2).
FetchVertexXY:
  LD H,$FD
  LD A,B
  ADD A,A
  LD L,A
  LD E,(HL)
  INC L
  LD D,(HL)
  DEC L
  INC H
  EX DE,HL
  LD BC,(l_9A85+$0009)
  ADD HL,BC
  LD (FetchVertexDepth+$0012),HL
  EX DE,HL
  LD E,(HL)
  INC L
  LD D,(HL)
  DEC L
  INC H
  EX DE,HL
  LD BC,(l_9A9E+$0015)
  ADD HL,BC
  RET

; z + `$9A6C` - 96 of the vertex: the signed distance to the near plane
;
; Witness: L1 6220 (c1, death, m2erbe, missions, play, play2).
FetchVertexDepth:
  EX DE,HL
  LD E,(HL)
  INC L
  LD D,(HL)
  EX DE,HL
  LD BC,(l_9A5E+$000E)
  ADD HL,BC
  AND A
  LD BC,(l_9A5E+$0014)
  SBC HL,BC
  LD DE,$0000
  LD B,H
  LD C,L
  EXX
  RET

; Cut a face at the near plane (Sutherland-Hodgman on depth = 96) into
; PolyVerts `$6700`
;
; Walks the face's point offsets from IX; at each in / out change calls
; NearClipLine `$A42B` and appends the cut with AppendPolyVertex `$A677`.
; Returns carry = the polygon is complete (fill it), Z = go on with the next
; point, NZ = nothing left.
;
; Witness: L1 3987 (c1, death, m2erbe, missions, play, play2).
ClipPolyNear:
  PUSH DE
  EXX
  LD A,B
  LD (PolyClipVars+$0001),A
  LD A,(PanelGauges+$0001)
  CP B
  EXX
  JP Z,l_A591
  EX AF,AF'
  LD B,A
  SRL B
  SRL B
  EXX
  LD A,(GameVars)
  LD B,A
  SRL B
  SRL B
  CALL NearClipLine
  EXX
  LD C,L
  LD B,H
  POP HL
  CALL AppendPolyVertex
  PUSH HL
  LD A,(PolyClipVars+$0001)
  LD B,A
  LD H,$FC
l_A537:
  LD L,(IX+$00)
  INC IX
  LD C,L
  LD E,(HL)
  INC L
  LD D,(HL)
  LD A,D
  XOR $80
  OR E
  JP NZ,l_A567
  LD A,C
  LD (GameVars),A
  DJNZ l_A537
  LD B,C
  SRL B
  SRL B
  EXX
  LD A,(PolyClipVars)
  LD B,A
  SRL B
  SRL B
  CALL NearClipLine
  EXX
  LD C,L
  LD B,H
  POP HL
  CALL AppendPolyVertex
  SCF
  RET
l_A567:
  LD A,B
  LD (PolyClipVars+$0001),A
  LD B,C
  SRL B
  SRL B
  EXX
  LD A,(GameVars)
  LD B,A
  SRL B
  SRL B
  EXX
  CALL NearClipLine
  EXX
  LD B,H
  LD C,L
  POP HL
  CALL AppendPolyVertex
  EX DE,HL
  EXX
  LD A,(PolyClipVars+$0001)
  LD B,A
  DEC IX
  EXX
  LD H,$FC
  XOR A
  RET
l_A591:
  EX AF,AF'
  LD (GameVars),A
  EX AF,AF'
  EXX
  DEC B
  INC IX
  LD H,$FC
l_A59C:
  LD L,(IX+$00)
  LD C,L
  INC IX
  LD E,(HL)
  INC L
  LD D,(HL)
  LD A,D
  XOR $80
  OR E
  JP NZ,l_A5B7
  LD A,C
  LD (GameVars),A
  DJNZ l_A59C
  POP DE
  LD A,$01
  AND A
  RET
l_A5B7:
  LD A,B
  LD (PolyClipVars+$0001),A
  LD B,C
  LD A,B
  LD (WorldVars+$000F),A
  SRL B
  SRL B
  EXX
  LD A,(GameVars)
  LD B,A
  SRL B
  SRL B
  EXX
  CALL NearClipLine
  EXX
  LD C,L
  LD B,H
  POP HL
  CALL AppendPolyVertex
  PUSH HL
  LD A,(WorldVars+$000F)
  LD (GameVars),A
  LD L,A
  LD H,$FC
  LD C,(HL)
  INC L
  LD B,(HL)
  INC L
  LD E,(HL)
  INC L
  LD D,(HL)
  POP HL
  CALL AppendPolyVertex
  PUSH HL
  LD A,(PolyClipVars+$0001)
  DEC A
  JP Z,l_A637
  LD B,A
l_A5F6:
  EXX
  LD A,(IX+$00)
  INC IX
  LD H,$FC
  LD L,A
  LD C,(HL)
  INC L
  LD B,(HL)
  EX AF,AF'
  LD A,B
  XOR $80
  OR C
  JP Z,l_A655
  EX AF,AF'
  LD (GameVars),A
  INC L
  LD E,(HL)
  INC L
  LD D,(HL)
  POP HL
  CALL AppendPolyVertex
  PUSH HL
  EXX
  DJNZ l_A5F6
  LD A,(PolyClipVars)
  LD B,A
  SRL B
  SRL B
  EXX
  LD A,(IX-$01)
  LD B,A
  SRL B
  SRL B
  CALL NearClipLine
  EXX
  LD B,H
  LD C,L
  POP HL
  CALL AppendPolyVertex
  SCF
  RET
l_A637:
  LD A,(GameVars)
  LD B,A
  SRL B
  SRL B
  EXX
  LD A,(PolyClipVars)
  LD B,A
  SRL B
  SRL B
  EXX
  CALL NearClipLine
  EXX
  LD C,L
  LD B,H
  POP HL
  CALL AppendPolyVertex
  SCF
  RET
l_A655:
  EXX
  LD C,B
  DEC C
  LD B,$00
  ADD IX,BC
  EX AF,AF'
  LD B,A
  SRL B
  SRL B
  EXX
  LD A,(GameVars)
  LD B,A
  SRL B
  SRL B
  CALL NearClipLine
  EXX
  LD C,L
  LD B,H
  POP HL
  CALL AppendPolyVertex
  SCF
  RET

; Append (BC, DE) to the polygon list at HL and count it in `$66D5`
;
; Witness: L1 4168 (c1, death, m2erbe, missions, play, play2).
AppendPolyVertex:
  LD (HL),C
  INC L
  LD (HL),B
  INC L
  LD (HL),E
  INC L
  LD (HL),D
  INC L
  LD A,(PolyOutCount)
  INC A
  LD (PolyOutCount),A
  RET

; HL = 256 HL / DE (signed HL, positive DE) by logarithms; DE = log2 of the
; divisor, kept for a second DivideByLog
;
; Normalises DE to an 8-bit mantissa and an exponent, looks up LogFraction /
; LogInteger `$5C00`, then falls into DivideByLog. 283 939 calls (11
; recordings).
;
; Witness: L1 283939 (c1, controls, death, m10, m2erbe, m2ocean, menu,
; missions, play, play2, search).
Divide:
  EX DE,HL
  LD A,H
  AND A
  JR Z,l_A6AE
  CP $10
  JR NC,l_A6B8
  LD B,$01
  SRA H
  JR Z,l_A6A9
  RR L
  INC B
  SRA H
  JR Z,l_A6A9
  RR L
  INC B
  SRA H
  JR Z,l_A6A9
  RR L
  SRA H
  INC B
l_A6A9:
  RR L
  JP l_A6C9
l_A6AE:
  LD H,$5C
  LD A,(HL)
  INC H
  LD H,(HL)
  LD L,A
  EX DE,HL
  JP DivideByLog
l_A6B8:
  ADD HL,HL
  LD B,$07
  ADD HL,HL
  JR C,l_A6C6
  DEC B
  ADD HL,HL
  JR C,l_A6C6
  DEC B
  JP l_A6C8
l_A6C6:
  RR H
l_A6C8:
  LD L,H
l_A6C9:
  LD H,$5C
  LD A,B
  LD B,(HL)
  INC H
  ADD A,(HL)
  LD H,A
  LD L,B
  EX DE,HL

; HL = 256 HL / 2^(DE / 256): log of |HL|, minus DE, antilog by ExpFraction
; `$5E00`, the sign back
;
; The shift of the 9-bit mantissa is a self-patched `JR` into an `ADD HL,HL`
; chain (`$A739`, `$A75A`). A result below 1 gives 0 (`$A765`), an overflow
; `$3EE4` and carry (`$A769`). The most called 3D routine: 475 056 entries, 45
; permille.
;
; Witness: L1 475056 (c1, controls, death, m10, m2erbe, m2ocean, menu,
; missions, play, play2, search).
DivideByLog:
  LD A,H
  RLA
  JR NC,l_A6DE
  LD A,L
  CPL
  LD L,A
  LD A,H
  CPL
  LD H,A
  INC HL
  SCF
l_A6DE:
  EX AF,AF'
  LD A,H
  AND A
  JR Z,l_A705
  CP $10
  JR NC,l_A70A
  LD B,$09
  SRA H
  JR Z,l_A700
  RR L
  INC B
  SRA H
  JR Z,l_A700
  RR L
  INC B
  SRA H
  JR Z,l_A700
  RR L
  SRA H
  INC B
l_A700:
  RR L
  JP l_A71A
l_A705:
  LD B,$08
  JP l_A71A
l_A70A:
  ADD HL,HL
  LD B,$0F
  ADD HL,HL
  JR C,l_A717
  DEC B
  ADD HL,HL
  JR C,l_A717
  DEC B
  RL H
l_A717:
  RR H
  LD L,H
l_A71A:
  LD H,$5C
  LD A,B
  LD B,(HL)
  INC H
  ADD A,(HL)
  LD H,A
  LD L,B
  AND A
  SBC HL,DE
  JP M,ZeroQuotient
  LD A,H
  LD B,A
  LD H,$5E
  LD L,(HL)
  LD H,$01
  SUB $08
  JR NC,l_A750
  LD A,$07
  SUB B
  LD (l_A739+$0001),A
l_A739:
  JR NZ,l_A739
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD L,H
  LD H,$00

; Negate HL when the sign saved in F' is set
;
; Witness: L1 425915 (c1, death, m2erbe, missions, play, play2).
ApplySign:
  EX AF,AF'
  RET NC
  LD A,L
  CPL
  LD L,A
  LD A,H
  CPL
  LD H,A
  INC HL
  AND A
  RET
; This entry point is used by the routine at DivideByLog.
l_A750:
  LD A,$0F
  SUB B
  JR C,l_A769
  JR Z,l_A769
  LD (l_A75A+$0001),A
l_A75A:
  JR NZ,l_A75A
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  JR ApplySign

; HL = 0
;
; Witness: L1 24493 (c1, death, m2erbe, missions, play, play2).
ZeroQuotient:
  XOR A
  LD H,A
  LD L,A
  RET
; This entry point is used by the routine at ApplySign.
l_A769:
  LD HL,$3EE4
  CALL ApplySign
  SCF
  RET

; HL = -HL
;
; Witness: L1 308008 (c1, controls, death, m10, m2erbe, m2ocean, menu,
; missions, play, play2, search).
NegHL:
  LD A,H
  CPL
  LD H,A
  LD A,L
  CPL
  LD L,A
  INC HL
  RET

; A = a pseudo-random byte: two additive words patched in place mixed with R
; (the mission vector `$67D0`)
;
; Witness: L1 584 (c1, death, m2erbe, missions, play, play2).
Random:
  PUSH HL
  PUSH DE
  LD DE,$04D2
  LD HL,$0ECA
  LD (Random+$0003),HL
  ADD HL,DE
  EX DE,HL
  LD HL,$250B
  LD (Random+$0006),HL
  ADD HL,DE
  LD (Random+$000E),HL
  LD A,L
  XOR H
  LD H,A
  LD A,R
  ADD A,H
  POP DE
  POP HL
  RET

; A = |A| (the mission vector `$67D6`)
;
; Witness: L1 179580 (c1, death, m2erbe, missions, play, play2).
AbsA:
  AND A
  RET P
  NEG
  RET

; DE = -DE
;
; Witness: L1 2228 (c1, death, m2erbe, missions, play, play2).
NegDE:
  LD A,D
  CPL
  LD D,A
  LD A,E
  CPL
  LD E,A
  INC DE
  RET

; HL = -|HL|
;
; Witness: known only from the code (no recording runs it).
NegAbsHL:
  BIT 7,H
  RET NZ
  JR NegateHL

; HL = |HL|
;
; Witness: L1 2 (play).
AbsHL:
  BIT 7,H
  RET Z

; HL = -HL (the mission vector `$67D3`)
;
; Witness: L1 18194 (c1, death, m2erbe, missions, play, play2).
NegateHL:
  LD A,H
  CPL
  LD H,A
  LD A,L
  CPL
  LD L,A
  INC HL
  RET

; HL = H * 32 (the back-buffer row offset of row H)
;
; Witness: L1 71059 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions,
; play, play2, search).
HighTimes32:
  LD L,H

; HL = L * 32
;
; Witness: L1 72315 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions,
; play, play2, search).
LowTimes32:
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  RET

; HL = A * E, signed bytes, by quarter squares: ((A+E)^2 - A^2 - E^2) / 2
;
; When A + E overflows it uses A^2 + E^2 - (A-E)^2 (`$A7DD`). Tables SquareLow
; / SquareHigh `$5F00`.
;
; Witness: L1 107436 (c1, controls, death, m10, m2erbe, m2ocean, menu,
; missions, play, play2, search).
MulSigned:
  LD L,A
  LD H,$5F
  LD C,(HL)
  INC H
  LD B,(HL)
  ADD A,E
  JP PE,l_A7DD
  LD L,E
  LD D,(HL)
  DEC H
  LD E,(HL)
  LD L,A
  LD A,(HL)
  INC H
  LD H,(HL)
  LD L,A
  AND A
  SBC HL,BC
  AND A
  SBC HL,DE
  SRA H
  RR L
  RET
l_A7DD:
  LD A,L
  LD L,E
  SUB E
  LD D,(HL)
  DEC H
  LD E,(HL)
  LD L,A
  LD A,(HL)
  INC H
  LD H,(HL)
  LD L,A
  EX DE,HL
  ADD HL,BC
  AND A
  SBC HL,DE
  SRA H
  RR L
  RET

; HL = A * E / 128 rounded, signed bytes: the product with a sine of Sine8
;
; Witness: L1 66079 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions,
; play, play2, search).
MulFrac:
  LD L,A
  LD H,$5F
  LD C,(HL)
  INC H
  LD B,(HL)
  ADD A,E
  JP PE,l_A815
  LD L,E
  LD D,(HL)
  DEC H
  LD E,(HL)
  LD L,A
  LD A,(HL)
  INC H
  LD H,(HL)
  LD L,A
  AND A
  SBC HL,BC
  AND A
  SBC HL,DE
  LD A,H
  RLA
  SBC A,A
  RL L
  LD L,H
  LD H,A
  RET NC
  INC HL
  RET
l_A815:
  LD A,L
  LD L,E
  SUB E
  LD D,(HL)
  DEC H
  LD E,(HL)
  LD L,A
  LD A,(HL)
  INC H
  LD H,(HL)
  LD L,A
  EX DE,HL
  ADD HL,BC
  SBC HL,DE
  SBC A,A
  RL L
  LD L,H
  LD H,A
  RET NC
  INC HL
  RET

; HL = HL * A / 128 for a signed word HL and a signed byte A (two
; quarter-square products)
;
; The mission vector `$67D9`: 220 482 calls in play, 37 permille, most of them
; from the mission code turning positions.
;
; Witness: L1 220482 (c1, death, m2erbe, missions, play, play2).
MulWordByte:
  ADD HL,HL
  JR NC,l_A830
  INC H
l_A830:
  RR L
  LD E,H
  LD H,A
  PUSH HL
  LD L,A
  LD H,$5F
  LD C,(HL)
  INC H
  LD B,(HL)
  ADD A,E
  JP PE,l_A84E
  LD L,E
  LD D,(HL)
  DEC H
  LD E,(HL)
  LD L,A
  LD A,(HL)
  INC H
  LD H,(HL)
  LD L,A
  AND A
  SBC HL,BC
  JP l_A85B
l_A84E:
  LD A,L
  LD L,E
  SUB E
  LD D,(HL)
  DEC H
  LD E,(HL)
  LD L,A
  LD A,(HL)
  INC H
  LD H,(HL)
  LD L,A
  EX DE,HL
  ADD HL,BC
l_A85B:
  AND A
  SBC HL,DE
  POP DE
  LD A,D
  PUSH HL
  LD L,A
  LD H,$5F
  LD C,(HL)
  INC H
  LD B,(HL)
  ADD A,E
  JP PE,l_A87A
  LD L,E
  LD D,(HL)
  DEC H
  LD E,(HL)
  LD L,A
  LD A,(HL)
  INC H
  LD H,(HL)
  LD L,A
  AND A
  SBC HL,BC
  JP l_A887
l_A87A:
  LD A,L
  LD L,E
  SUB E
  LD D,(HL)
  DEC H
  LD E,(HL)
  LD L,A
  LD A,(HL)
  INC H
  LD H,(HL)
  LD L,A
  EX DE,HL
  ADD HL,BC
l_A887:
  AND A
  SBC HL,DE
  POP DE
  SRA D
  RR E
  XOR A
  BIT 7,H
  JR Z,l_A895
  DEC A
l_A895:
  LD L,H
  LD H,A
  ADD HL,DE
  RET

; A = Sine8[A], A' = Sine8[A + 64] (the mission vector `$67E8`)
;
; Witness: L1 58907 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions,
; play, play2, search).
SinCos8:
  LD H,$63
  LD L,A
  LD A,(HL)
  EX AF,AF'
  LD A,L
  ADD A,$40
  LD L,A
  LD A,(HL)
  EX AF,AF'
  RET

; DE = Sine16[A], BC = Sine16[A + 64]
;
; Witness: L1 4970 (c1, death, missions, play, play2).
SinCos16:
  LD H,$61
  LD L,A
  LD E,(HL)
  INC H
  LD D,(HL)
  ADD A,$40
  LD L,A
  LD B,(HL)
  DEC H
  LD C,(HL)
  RET

; E = A = sine, A = cosine of the angle word HL (H the angle, bit 7 of L the
; half step: Sine8Half `$6400`)
;
; Witness: L1 22941 (c1, death, m2erbe, missions, play, play2).
SinCosHalf:
  RL L
  LD L,H
  JP C,l_A8BD
  LD H,$63
  JP l_A8BF
l_A8BD:
  LD H,$64
l_A8BF:
  LD A,(HL)
  LD E,A
  LD A,$40
  ADD A,L
  LD L,A
  LD A,(HL)
  RET

  ORG $AA27

; Set the pixel (x = L, y = H) in the back buffer (the bit masks at `$7C49`)
;
; Caller `$BB75` (points of the scenery). 37 012 calls.
;
; Witness: L1 37012 (c1, death, m2erbe, missions, play, play2).
PlotBackBuffer:
  LD A,L
  EX AF,AF'
  LD A,H
  CALL HighTimes32
  LD DE,BackBuffer
  ADD HL,DE
  EX AF,AF'
  LD D,$00
  LD E,A
  SRL E
  SRL E
  SRL E
  ADD HL,DE
  AND $07
  ADD A,$49
  LD E,A
  LD D,$7C
  LD A,(DE)
  OR (HL)
  LD (HL),A
  RET
