; --------------------------------------------------------------------------------------------------------------------
; im2.asm: The IM 2 set-up, the handler and the table
; --------------------------------------------------------------------------------------------------------------------

  ORG $F629

; Copy the three bytes at Im2Jump (TurboLoad's code) to SavedLoaderBytes
;
; Witness: L1 5 (c1, joystick, stageload).
SaveLoaderBytes:
  LD HL,Im2Jump
  LD DE,SavedLoaderBytes
  LD BC,$0003
  LDIR
  RET

; Im2Jump := JP HL, I := $FD, IM 2, EI
;
; Im2Table ($FD00-$FE00, all $FE) sends every interrupt to Im2Jump at $FEFE.
; Witness: L1 5 (c1, joystick, stageload).
SetIm2:
  DI
  LD A,$C3
  LD (Im2Jump),A
  LD (Im2Jump+$0001),HL
  LD A,$FD
  LD I,A
  IM 2
  EI
  RET

  ORG $F66C

; TurboLoad's three bytes at Im2Jump while the IM 2 jump is there
;
; Written by SaveLoaderBytes, read back by LoadBlock (c1).
SavedLoaderBytes:
  DEFB $00,$00,$00

  ORG $F9B3

; The interrupt: AyFrame in the alternate registers, EI, RETI
;
; Witness: L1 125688 (c1, c1o, deaths, ending, joystick, menu, s1-idle,
; s1-right, s2-right, s3-right, s4-right, s5-right, stageload, rzx-r0-rzx-r5).
Im2Handler:
  EXX
  EX AF,AF'
  CALL AyFrame
  EX AF,AF'
  EXX
  EI
  RETI

  ORG $FD00

; 257 bytes of $FE: whatever the bus holds, the vector is $FEFE (Im2Jump)
;
; Read by the Z80 at every interrupt (I = $FD), c1 and every recording.
Im2Table:
  DEFB $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
  DEFB $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
  DEFB $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
  DEFB $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
  DEFB $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
  DEFB $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
  DEFB $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
  DEFB $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
  DEFB $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
  DEFB $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
  DEFB $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
  DEFB $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
  DEFB $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
  DEFB $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
  DEFB $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
  DEFB $FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE,$FE
  DEFB $FE
